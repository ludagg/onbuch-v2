#!/usr/bin/env python3
# OnBuch — Collecte des documents « COURS » de la base (export / rapport).
#
# Scanne RAPIDEMENT toute la collection `annales` (pagination par curseur +
# sélection de champs) et repère les documents qui sont des **cours** :
#   • catégorie == « Cours », OU
#   • mots-clés de cours détectés dans le titre (COURS, LEÇON, MÉMENTO,
#     RAPPEL/NOTES/SUPPORT DE COURS…) — pour rattraper les cours mal catégorisés.
# Les fiches de révision et les TD sont volontairement EXCLUS.
#
# EXPORT-ONLY : écrit un rapport (JSON + CSV) et n'écrit RIEN dans la base.
#
# Usage :
#   APPWRITE_API_KEY="standard_xxx" python3 tools/collect_course_docs.py [DOSSIER_SORTIE]
# Sortie par défaut : ./course_docs_export/{course_docs.json, course_docs.csv}
#
# Clé API **serveur** avec scope `databases.read` (lecture seule).

import os, sys, json, csv, subprocess, urllib.parse, unicodedata, time
from collections import Counter

EP = os.environ.get('APPWRITE_ENDPOINT', 'https://nyc.cloud.appwrite.io/v1')
PROJ = os.environ.get('APPWRITE_PROJECT', '6a30463b00001375e229')
DB = os.environ.get('APPWRITE_DATABASE', '6a3047f8001d11d1b3c1')
KEY = os.environ.get('APPWRITE_API_KEY') or sys.exit('Définis APPWRITE_API_KEY (clé serveur, scope databases.read)')
COL = os.environ.get('ANNALES_COLLECTION', 'annales')
OUT = sys.argv[1] if len(sys.argv) > 1 else 'course_docs_export'

# Champs récupérés (Query.select → payload réduit = scan plus rapide).
FIELDS = ['title', 'subject', 'exam', 'track', 'category', 'year', 'session',
          'fileUrl', 'corrigeUrl', 'videoUrl']

# Mots-clés « cours » (normalisés : majuscules, sans accent). On cible le COURS,
# pas les fiches ni les TD (exclus par le choix produit).
KW = ['COURS COMPLET', 'RESUME DE COURS', 'RAPPEL DE COURS', 'RAPPELS DE COURS',
      'NOTES DE COURS', 'SUPPORT DE COURS', 'SUPPORTS DE COURS', 'LECON', 'LECONS',
      'MEMENTO', 'COURS']
# Quelques faux positifs fréquents à neutraliser avant le test de « COURS ».
KW_EXCLUDE = ["COURS D'EAU", 'COURS D EAU']
# Catégories explicitement non-cours (ne JAMAIS inclure via le titre).
CAT_EXCLUDE = {'fiche de revision', 'td'}


def norm(s):
    s = (s or '').upper()
    return ''.join(c for c in unicodedata.normalize('NFD', s) if unicodedata.category(c) != 'Mn')


def curl(url):
    cmd = ['curl', '-sS', '-m', '40', url,
           '-H', f'X-Appwrite-Project: {PROJ}', '-H', f'X-Appwrite-Key: {KEY}']
    r = subprocess.run(cmd, capture_output=True, text=True)
    try:
        return json.loads(r.stdout)
    except Exception:
        sys.exit(f'Réponse inattendue: {r.stdout[:300]}\n{r.stderr[:300]}')


def q(obj):
    return 'queries[]=' + urllib.parse.quote(json.dumps(obj))


def detect(doc):
    """Renvoie la raison de classement « cours », ou None."""
    cat = (doc.get('category') or '').strip().lower()
    if cat == 'cours':
        return 'categorie'
    if cat in CAT_EXCLUDE:
        return None  # fiche/TD : jamais via le titre
    t = norm(doc.get('title'))
    for x in KW_EXCLUDE:
        t = t.replace(x, ' ')
    for k in KW:
        if k in t:
            return 'titre:' + k
    return None


def main():
    print(f'Scan de la collection « {COL} » (rapide, par curseur)…')
    t0 = time.time()
    matches, scanned, cursor, total = [], 0, None, None
    while True:
        qs = [q({'method': 'limit', 'values': [1000]}),
              q({'method': 'select', 'values': FIELDS})]
        if cursor:
            qs.append(q({'method': 'cursorAfter', 'values': [cursor]}))
        data = curl(f'{EP}/databases/{DB}/collections/{COL}/documents?' + '&'.join(qs))
        if 'documents' not in data:
            sys.exit(f'Erreur API: {json.dumps(data)[:300]}')
        batch = data['documents']
        total = data.get('total', total)
        if not batch:
            break
        for d in batch:
            scanned += 1
            reason = detect(d)
            if reason:
                matches.append({
                    'id': d['$id'], 'detect': reason,
                    'category': d.get('category', ''), 'exam': d.get('exam', ''),
                    'track': d.get('track', ''), 'subject': d.get('subject', ''),
                    'year': d.get('year', ''), 'session': d.get('session', ''),
                    'title': d.get('title', ''),
                    'fileUrl': d.get('fileUrl', ''), 'corrigeUrl': d.get('corrigeUrl', ''),
                    'videoUrl': d.get('videoUrl', ''),
                })
        cursor = batch[-1]['$id']
        sys.stdout.write(f'\r  scannés: {scanned}  ·  cours trouvés: {len(matches)}')
        sys.stdout.flush()
        if len(batch) < 1000:
            break
    dt = time.time() - t0
    print(f'\nTerminé en {dt:.1f}s — {scanned} documents scannés'
          + (f' (total annoncé: {total})' if total is not None else ''))

    # Tri lisible : examen → matière → titre.
    matches.sort(key=lambda m: (m['exam'].lower(), m['subject'].lower(), m['title'].lower()))

    os.makedirs(OUT, exist_ok=True)
    jpath = os.path.join(OUT, 'course_docs.json')
    cpath = os.path.join(OUT, 'course_docs.csv')
    with open(jpath, 'w', encoding='utf-8') as f:
        json.dump(matches, f, ensure_ascii=False, indent=2)
    cols = ['id', 'detect', 'category', 'exam', 'track', 'subject', 'year', 'session',
            'title', 'fileUrl', 'corrigeUrl', 'videoUrl']
    with open(cpath, 'w', encoding='utf-8', newline='') as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        w.writerows(matches)

    # Résumé.
    by_reason = Counter(m['detect'].split(':')[0] for m in matches)
    by_exam = Counter(m['exam'] or '∅' for m in matches)
    by_subj = Counter(m['subject'] or '∅' for m in matches)
    with_pdf = sum(1 for m in matches if (m['fileUrl'] or '').strip())
    print('\n── Résumé ──')
    print(f'  COURS trouvés : {len(matches)}  ·  avec PDF : {with_pdf}')
    print(f'  par détection : {dict(by_reason)}')
    print('  par examen    : ' + ', '.join(f'{k}={v}' for k, v in by_exam.most_common()))
    print('  top matières  : ' + ', '.join(f'{k}={v}' for k, v in by_subj.most_common(10)))
    print(f'\n  → {jpath}\n  → {cpath}')


if __name__ == '__main__':
    main()
