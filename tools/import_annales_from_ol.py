#!/usr/bin/env python3
"""Classe les documents OL (sujetexa) vers la collection `annales` d'OnBuch.

Source  : base SQLite OL (`Document`) — ~37k PDF scrapés.
Cible   : collection Appwrite `annales` (schéma : exam, track, subject, category,
          year, session, title, fileUrl, corrigeUrl, videoUrl, premium).

Règle « ne prendre que ce qui concerne OnBuch » : un document n'est conservé que
si on peut le rattacher à un couple (exam, subject) RÉELLEMENT présent dans la
taxonomie de l'app (`lib/data/exam_taxonomy.dart`) — sinon il est inaccessible
dans l'app. Les classes hors-examen (6e/5e/4e, Seconde) sont donc écartées.

Usage :
  # Analyse seule (aucune écriture) :
  python3 tools/import_annales_from_ol.py --db /home/user/ol/db/custom.db --dry-run

  # Écrire le JSON classé (pour revue / import) :
  python3 tools/import_annales_from_ol.py --db ... --out /tmp/annales.json

  # Insertion réelle dans Appwrite (par lots) :
  APPWRITE_API_KEY=standard_xxx python3 tools/import_annales_from_ol.py \
      --db ... --insert [--limit N]
"""
import argparse, json, os, re, sqlite3, sys, time, urllib.request, urllib.error

# ── Taxonomie : sous-ensembles VALIDES de matières par examen ────────────────
# Repris fidèlement de lib/data/exam_taxonomy.dart (union des matières de toutes
# les séries d'un examen). Un `subject` produit doit appartenir à ce set, sinon
# le doc serait orphelin dans l'app → on le jette.
_BAC = {
    'Mathématiques','Physique','Chimie','SVT','Technologie','Construction mécanique',
    'Informatique','Philosophie','Français','Anglais','Histoire','Géographie','ECM',
    'Littérature','Latin','Grec','LV3','LV2','Arts plastiques','Musique','Bilingual Studies',
    'Économie','Droit','Communication administrative','Organisation & Gestion',
    'Communication commerciale','Mercatique','Comptabilité','Mathématiques financières',
    'Fiscalité','Informatique de gestion','Sciences sociales','Hôtellerie','Restauration',
    'Gestion hôtelière','Fabrication','Automatisme','Électronique','Électrotechnique',
    'Mesures électriques','Béton armé','Construction','Topographie','Résistance des matériaux',
    'Froid et climatisation','Thermodynamique','Génie chimique','Chimie industrielle',
    'Biochimie','Microbiologie','Sciences sanitaires','Biologie','Maintenance',
}
_PROB = _BAC - {'Philosophie'}
_BEPC = {'Français','Anglais','Mathématiques','SVT','Physique-Chimie','Histoire',
         'Géographie','ECM','LV2','Informatique'}
_GCE_O = {'Mathematics','Additional Mathematics','Physics','Chemistry','Biology',
          'Human Biology','Geology','Computer Science','Geography','Food and Nutrition',
          'English Language','Literature in English','French','Special Bilingual Education (French)',
          'History','Economics','Commerce','Accounting','Citizenship Education',
          'Religious Studies','Logic'}
_GCE_A = {'Mathematics','Further Mathematics','Physics','Chemistry','Biology','Geology',
          'Computer Science','Geography','Food Science & Nutrition','English Literature',
          'French','History','Economics','Commerce','Accounting','Management','Philosophy',
          'Religious Studies','Logic'}
_CAP = {'Français','Mathématiques','Anglais','Travaux pratiques','Comptabilité',
        'Technologie du bois','Technologie du bâtiment','Électrotechnique','Électronique',
        'Informatique','Économie d\'entreprise'}
_BT = {'Français','Mathématiques','Anglais','Physique','Électrotechnique','Électronique',
       'Construction mécanique','Béton armé','Topographie','Maintenance','Comptabilité','Gestion'}

VALID = {
    'Baccalauréat': _BAC, 'Probatoire': _PROB, 'BEPC': _BEPC,
    'GCE A Level': _GCE_A, 'GCE O Level': _GCE_O, 'CAP': _CAP, 'BT': _BT,
}

# ── Normalisation des matières (préfixe de catégorie → matière taxonomie) ─────
PREFIX_SUBJECT = {
    'MATHS': 'Mathématiques', 'MATHEMATIQUES': 'Mathématiques',
    'FRANCAIS': 'Français', 'FRANÇAIS': 'Français',
    'PHYSIQUE': 'Physique', 'CHIMIE': 'Chimie', 'PCT': 'Physique-Chimie',
    'SVT': 'SVT', 'INFORMATIQUE': 'Informatique', 'INFO': 'Informatique',
    'ANGLAIS': 'Anglais', 'ESPAGNOL': 'LV2', 'ALLEMAND': 'LV2',
    'ECM': 'ECM', 'HISTOIRE': 'Histoire', 'GEOGRAPHIE': 'Géographie',
    'HG': 'Histoire', 'PHILOSOPHIE': 'Philosophie', 'PHILO': 'Philosophie',
    'LITTERATURE': 'Littérature',
}
# Mots-clés en titre → matière (pour Non classé / techniques), FR + GCE.
TITLE_SUBJECT = [
    (r'\bMATH', 'Mathématiques'), (r'\bFRAN[CÇ]AIS', 'Français'),
    (r'PHYSIQUE-?CHIMIE|\bPCT\b', 'Physique-Chimie'), (r'\bPHYSIQUE', 'Physique'),
    (r'\bCHIMIE', 'Chimie'), (r'\bSVT|SCIENCES DE LA VIE', 'SVT'),
    (r'INFORMATIQUE', 'Informatique'), (r'\bANGLAIS|\bENGLISH', 'Anglais'),
    (r'ESPAGNOL|ALLEMAND', 'LV2'), (r'\bECM\b|EDUCATION (A LA )?CITOYEN', 'ECM'),
    (r'PHILOSOPHIE', 'Philosophie'), (r'HISTOIRE', 'Histoire'),
    (r'G[EÉ]OGRAPHIE', 'Géographie'), (r'LITT[EÉ]RATURE', 'Littérature'),
    (r'COMPTABILIT[EÉ]', 'Comptabilité'), (r'\bDROIT\b', 'Droit'),
    (r'[EÉ]CONOMIE', 'Économie'), (r'[EÉ]LECTROTECHNIQUE', 'Électrotechnique'),
    (r'[EÉ]LECTRONIQUE', 'Électronique'), (r'B[EÉ]TON ARM', 'Béton armé'),
    (r'TOPOGRAPHIE', 'Topographie'), (r'BIOLOGIE|BIOCHIMIE', 'Biologie'),
]
# Matières GCE (titres anglais).
GCE_TITLE_SUBJECT = [
    (r'FURTHER MATH', 'Further Mathematics'), (r'ADDITIONAL MATH', 'Additional Mathematics'),
    (r'MATHEMATIC', 'Mathematics'), (r'\bPHYSICS', 'Physics'), (r'CHEMISTRY', 'Chemistry'),
    (r'HUMAN BIOLOGY', 'Human Biology'), (r'BIOLOGY', 'Biology'), (r'GEOLOGY', 'Geology'),
    (r'COMPUTER', 'Computer Science'), (r'GEOGRAPHY', 'Geography'),
    (r'LITERATURE', None),  # résolu plus bas selon niveau
    (r'ENGLISH', 'English Language'), (r'\bFRENCH', 'French'), (r'HISTORY', 'History'),
    (r'ECONOMICS', 'Economics'), (r'COMMERCE', 'Commerce'), (r'ACCOUNTING', 'Accounting'),
    (r'CITIZENSHIP', 'Citizenship Education'), (r'RELIGIOUS', 'Religious Studies'),
    (r'\bLOGIC', 'Logic'), (r'MANAGEMENT', 'Management'),
]

# Suffixe de classe → (exam, track)
SUFFIX_EXAM = {
    '3': ('BEPC', ''), '3E': ('BEPC', ''),
    'TA': ('Baccalauréat', 'A'), 'TC': ('Baccalauréat', 'C'), 'TD': ('Baccalauréat', 'D'),
    'PA': ('Probatoire', 'A'), 'PC': ('Probatoire', 'C'), 'PD': ('Probatoire', 'D'),
}

YEAR_RE = re.compile(r'(?:19|20)\d{2}')
URL_YEAR_RE = re.compile(r'/((?:19|20)\d{2})/')


def norm_subject_for_exam(subject, exam):
    """Adapte une matière au vocabulaire exact de l'examen (ex. BEPC=Physique-Chimie)."""
    if not subject:
        return None
    if exam == 'BEPC':
        if subject in ('Physique', 'Chimie', 'Physique-Chimie'):
            subject = 'Physique-Chimie'
    if subject in VALID.get(exam, set()):
        return subject
    return None


def detect_year(title, url):
    for m in YEAR_RE.findall(title or ''):
        y = int(m)
        if 1995 <= y <= 2026:
            return str(y)
    m = URL_YEAR_RE.search(url or '')
    if m:
        return m.group(1)
    return ''


def detect_doctype(cat, title):
    """(category_onbuch, is_corrige) — corrigé seul va dans corrigeUrl."""
    t = (title or '').upper()
    c = (cat or '').upper()
    if c.startswith('CORRIG') or 'CORRIG' in c or re.search(r'\bCORRIG|\bCORRECTION', t):
        return 'Épreuve', True
    if c.startswith('FASCICULE') or 'FASCICULE' in c:
        return 'Fiche de révision', False
    if c == 'COURS' or re.search(r'\bCOURS\b', t):
        return 'Cours', False
    if 'TD' in c.split() or 'FICHES TD' in c or re.search(r'\bTRAVAUX DIRIG|\bT\.?D\.?\b', t):
        return 'TD', False
    if 'EXERCICE' in c:
        return 'TD', False
    return 'Épreuve', False


def detect_session(cat, title):
    t = (title or '').upper()
    c = (cat or '').upper()
    if 'ZÉRO' in c or 'ZERO' in c or 'ÉPREUVE ZÉRO' in t or 'EPREUVE ZERO' in t:
        return 'Épreuve zéro'
    if 'HARMONISE' in t or 'HARMONISÉ' in t:
        return 'Corrigé harmonisé national'
    for pat, label in [
        (r'BAC ?BLANC', 'Bac blanc'), (r'BEPC ?BLANC', 'BEPC blanc'),
        (r'PROBATOIRE ?BLANC|PROB ?BLANC', 'Probatoire blanc'),
        (r'CONCOURS BLANC', 'Concours blanc'), (r'MOCK', 'Mock'),
    ]:
        if re.search(pat, t):
            return label
    m = re.search(r'S[EÉ]QUENCE\s*N?°?\s*(\d)', t)
    if m:
        return f'Séquence {m.group(1)}'
    if 'SESSION' in t:
        return 'Session normale'
    return ''


def gce_subject(title, level):
    t = (title or '').upper()
    valid = _GCE_A if level == 'A' else _GCE_O
    for pat, subj in GCE_TITLE_SUBJECT:
        if re.search(pat, t):
            if subj is None:  # LITERATURE
                subj = 'English Literature' if level == 'A' else 'Literature in English'
            if subj in valid:
                return subj
    return None


def title_subject(title, exam):
    """Matière FR depuis le titre, validée pour l'examen."""
    t = (title or '').upper()
    for pat, subj in TITLE_SUBJECT:
        if re.search(pat, t):
            s = norm_subject_for_exam(subj, exam)
            if s:
                return s
    return None


def classify(row):
    """row -> dict annale | None (rejeté). Renvoie aussi un motif de rejet."""
    title = (row['title'] or '').strip()
    cat = (row['category'] or '').strip()
    url = (row['fileUrl'] or '').strip()
    cat_u = cat.upper()

    exam = track = subject = None

    # 1) Codes encodés SUBJECT_CLASS (ex. MATHS_TC, FRANÇAIS_PA, SVT_3)
    if '_' in cat and not cat_u.startswith(('CORRIG', 'FASCICULE', 'EPREUVE')):
        pre, _, suf = cat.partition('_')
        suf = suf.upper().strip()
        subj0 = PREFIX_SUBJECT.get(pre.upper().strip())
        ex = SUFFIX_EXAM.get(suf)
        if subj0 and ex:
            exam, track = ex
            subject = norm_subject_for_exam(subj0, exam)

    # 2) CORRIGÉS-xx / FASCICULES-xx / EPREUVES ZÉRO-xx → suffixe = classe
    if exam is None and ('-' in cat) and cat_u.startswith(('CORRIG', 'FASCICULE', 'EPREUVE')):
        suf = cat.rsplit('-', 1)[-1].upper().strip()
        ex = SUFFIX_EXAM.get(suf)
        if ex:
            exam, track = ex
            subject = title_subject(title, exam)

    # 3) Catégories techniques / examens explicites
    if exam is None:
        if cat_u.startswith('BAC') or cat_u == 'BACCALAURÉAT STT':
            exam = 'Baccalauréat'
            track = cat.replace('BAC', '').replace('BACCALAURÉAT', '').strip() or ''
            subject = title_subject(title, exam)
        elif cat_u.startswith('PROBATOIRE') or cat_u == 'SERIE STT':
            exam = 'Probatoire'
            track = cat.replace('PROBATOIRE', '').strip()
            subject = title_subject(title, exam)
        elif cat_u.startswith('CAP'):
            exam = 'CAP'; track = cat.replace('CAP', '').strip()
            subject = title_subject(title, exam)
        elif cat_u.startswith('BREVET DE TECHNICIEN'):
            exam = 'BT'; track = ''
            subject = title_subject(title, exam)
        elif cat_u in ('GCE AL', 'LOWER AND UPPER SIXTH') or 'A LEVEL' in cat_u or 'A/LEVEL' in title.upper():
            exam = 'GCE A Level'; subject = gce_subject(title, 'A')
        elif cat_u in ('GCE OL',) or cat_u.startswith('FORM ') or 'O LEVEL' in cat_u or 'O/LEVEL' in title.upper():
            exam = 'GCE O Level'; subject = gce_subject(title, 'O')
        elif cat_u == 'GCE':
            lvl = 'A' if re.search(r'A[ /]?LEVEL|UPPER SIXTH', title.upper()) else 'O'
            exam = 'GCE A Level' if lvl == 'A' else 'GCE O Level'
            subject = gce_subject(title, lvl)

    # 4) Non classé / divers → tout déduire du titre
    if exam is None:
        T = title.upper()
        if re.search(r'\bTLE|\bT[ABCDE]\d?\b|TERMINALE|\bBAC(?!C)', T):
            exam = 'Baccalauréat'
        elif re.search(r'PREMI[EÉ]RE|\b1[EÈ]RE|\bP[ABCD]\b|PROBATOIRE', T):
            exam = 'Probatoire'
        elif re.search(r'\b3[EÈ]ME|TROISI[EÈ]ME|\bBEPC\b', T):
            exam = 'BEPC'
        if exam:
            subject = title_subject(title, exam)

    # ── Validation finale ────────────────────────────────────────────────────
    if exam is None:
        return None, 'exam_inconnu'
    if not subject:
        return None, 'matiere_non_resolue'
    if subject not in VALID.get(exam, set()):
        return None, 'matiere_hors_taxonomie'
    if not url:
        return None, 'sans_lien'
    if re.search(r'\.(jpe?g|png|gif|webp)(\?|$)', url, re.I):
        return None, 'lien_image'

    onbuch_cat, is_corrige = detect_doctype(cat, title)
    year = detect_year(title, url)
    session = detect_session(cat, title)

    doc = {
        'exam': exam, 'track': track or '', 'subject': subject,
        'category': onbuch_cat, 'year': year, 'session': session,
        'title': title[:200],
        'fileUrl': '' if is_corrige else url,
        'corrigeUrl': url if is_corrige else '',
        'videoUrl': '', 'premium': False,
    }
    return doc, None


def load_rows(db_path):
    con = sqlite3.connect(db_path); con.row_factory = sqlite3.Row
    cur = con.cursor()
    cur.execute('SELECT title, category, fileUrl FROM Document WHERE published=1')
    rows = cur.fetchall(); con.close()
    return rows


def run(args):
    rows = load_rows(args.db)
    kept, rejects = [], {}
    seen = set()
    dups = 0
    for r in rows:
        doc, reason = classify(r)
        if doc is None:
            rejects[reason] = rejects.get(reason, 0) + 1
            continue
        key = doc['fileUrl'] or doc['corrigeUrl']  # 1 doc par lien (table OL doublée)
        if key in seen:
            dups += 1
            continue
        seen.add(key)
        kept.append(doc)

    total = len(rows)
    print(f'\n=== Classification de {total} documents OL ===')
    print(f'  ✓ conservés (mappables OnBuch) : {len(kept)}')
    print(f'  ✗ doublons ignorés            : {dups}')
    print('  ✗ rejetés :')
    for k, v in sorted(rejects.items(), key=lambda x: -x[1]):
        print(f'      {v:6d}  {k}')

    from collections import Counter
    print('\n  Répartition par examen :')
    for ex, n in Counter(d['exam'] for d in kept).most_common():
        print(f'      {n:6d}  {ex}')
    print('\n  Répartition par type :')
    for c, n in Counter(d['category'] for d in kept).most_common():
        print(f'      {n:6d}  {c}')
    print('\n  Top matières :')
    for s, n in Counter(f"{d['exam']} · {d['subject']}" for d in kept).most_common(25):
        print(f'      {n:6d}  {s}')

    if args.out:
        with open(args.out, 'w') as f:
            json.dump(kept, f, ensure_ascii=False, indent=1)
        print(f'\n  → {len(kept)} documents écrits dans {args.out}')

    if args.sample:
        print('\n  Échantillon (15) :')
        import random
        for d in random.sample(kept, min(15, len(kept))):
            print('   ', json.dumps({k: d[k] for k in ('exam','track','subject','category','year','session','title')}, ensure_ascii=False)[:200])

    if args.insert:
        insert_appwrite(kept, args)


def insert_appwrite(docs, args):
    endpoint = os.environ.get('APPWRITE_ENDPOINT', 'https://nyc.cloud.appwrite.io/v1')
    project = os.environ.get('APPWRITE_PROJECT', '6a30463b00001375e229')
    db = os.environ.get('APPWRITE_DATABASE', '6a3047f8001d11d1b3c1')
    key = os.environ.get('APPWRITE_API_KEY')
    if not key:
        sys.exit('APPWRITE_API_KEY requis pour --insert')
    url = f'{endpoint}/databases/{db}/collections/annales/documents'
    headers = {'X-Appwrite-Project': project, 'X-Appwrite-Key': key,
               'Content-Type': 'application/json'}
    if args.limit:
        docs = docs[:args.limit]
    ok = err = 0
    t0 = time.time()
    for i, d in enumerate(docs):
        body = json.dumps({'documentId': 'unique()', 'data': d}).encode()
        req = urllib.request.Request(url, data=body, headers=headers, method='POST')
        try:
            urllib.request.urlopen(req, timeout=30)
            ok += 1
        except urllib.error.HTTPError as e:
            err += 1
            if err <= 5:
                print('  HTTP', e.code, e.read()[:200])
            if e.code == 429:
                time.sleep(2)
        except Exception as e:
            err += 1
            if err <= 5:
                print('  ERR', e)
            time.sleep(1)
        if (i + 1) % 250 == 0:
            rate = (i + 1) / (time.time() - t0)
            print(f'  …{i+1}/{len(docs)}  ok={ok} err={err}  {rate:.1f}/s')
    print(f'\n  Insertion terminée : ok={ok} err={err} en {time.time()-t0:.0f}s')


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--db', default='/home/user/ol/db/custom.db')
    ap.add_argument('--out')
    ap.add_argument('--dry-run', action='store_true')
    ap.add_argument('--sample', action='store_true')
    ap.add_argument('--insert', action='store_true')
    ap.add_argument('--limit', type=int)
    run(ap.parse_args())
