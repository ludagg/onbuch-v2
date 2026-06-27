#!/usr/bin/env python3
# Aligne les matières des COURS (collection `subjects`) sur les RESSOURCES
# (collection `exam_series`, gérée par l'admin), qui utilisent « Histoire » et
# « Géographie » comme DEUX matières distinctes (cursus camerounais).
#
# Le contenu des cours avait une matière combinée « Histoire-Géo » par examen
# (Bac, Probatoire, BEPC) avec 12 chapitres chacun. On la SCINDE en deux :
#   - on renomme le doc existant en « Histoire » (garde son id, ses chapitres
#     d'histoire, et d'éventuels achats/progrès rattachés) ;
#   - on crée un nouveau doc « Géographie » (mêmes réglages : examen, série,
#     premium, prix, coef, aperçu) ;
#   - on déplace les chapitres de géographie vers ce nouveau doc.
#
# Classement des chapitres : préfixe « Histoire — »/« Géographie — » s'il existe
# (Bac), sinon liste explicite des titres de géographie (Probatoire, BEPC),
# comparée après normalisation (sans accents/casse/ponctuation). Tout le reste
# reste en Histoire.
#
# Idempotent : si « Histoire » et « Géographie » existent déjà pour l'examen, on
# saute. DRY par défaut ; APPLY=1 pour écrire.
#   APPWRITE_API_KEY="standard_xxx" python3 tools/split_histoire_geo.py
#   APPWRITE_API_KEY="standard_xxx" APPLY=1 python3 tools/split_histoire_geo.py
import os, sys, json, subprocess, urllib.parse, unicodedata

KEY = os.environ.get('APPWRITE_API_KEY') or sys.exit('Définis APPWRITE_API_KEY')
APPLY = os.environ.get('APPLY') == '1'
EP = "https://nyc.cloud.appwrite.io/v1/databases/6a3047f8001d11d1b3c1"
H = ['-H', 'X-Appwrite-Project: 6a30463b00001375e229', '-H', f'X-Appwrite-Key: {KEY}', '-H', 'Content-Type: application/json']

COMBINED = {'histoiregeo', 'histoiregeographie'}  # noms (normalisés) à scinder

# Titres de chapitres de GÉOGRAPHIE (hors Bac qui est préfixé), tels que stockés.
GEO_TITLES = [
    # Probatoire
    "La population mondiale et sa répartition",
    "L'urbanisation dans le monde",
    "Les grands domaines climatiques et bioclimatiques",
    "Les activités économiques : agriculture et industrie",
    "Le Cameroun : milieu naturel et population",
    # BEPC
    "Le Cameroun : relief, climat, vegetation et hydrographie",
    "La population du Cameroun",
    "Les activites economiques du Cameroun",
    "L'Afrique : presentation generale",
    "Les grands ensembles du monde",
]


def norm(s):
    s = unicodedata.normalize('NFKD', s or '')
    s = ''.join(c for c in s if not unicodedata.combining(c)).lower()
    return ''.join(c for c in s if c.isalnum())


GEO_NORM = {norm(t) for t in GEO_TITLES}


def api(method, path, body=None):
    cmd = ['curl', '-s', '-X', method, EP + path] + H + (['-d', json.dumps(body)] if body is not None else []) + ['-w', '\n%{http_code}']
    out = subprocess.run(cmd, capture_output=True, text=True).stdout
    b, _, code = out.rpartition('\n')
    return code, b


def all_docs(col):
    docs, off = [], 0
    while True:
        q1 = urllib.parse.quote(json.dumps({"method": "limit", "values": [100]}))
        q2 = urllib.parse.quote(json.dumps({"method": "offset", "values": [off]}))
        _, b = api('GET', f"/collections/{col}/documents?queries[]={q1}&queries[]={q2}")
        page = json.loads(b).get('documents', [])
        docs += page
        if len(page) < 100:
            break
        off += 100
    return docs


def is_geo(title):
    n = norm(title)
    if n.startswith('geographie'):
        return True
    if n.startswith('histoire'):
        return False
    return n in GEO_NORM


subs = all_docs('subjects')
chaps = all_docs('chapters')
by_name_exam = {}
for s in subs:
    by_name_exam.setdefault((norm(s.get('name', '')), s.get('exam', '')), s)

targets = [s for s in subs if norm(s.get('name', '')) in COMBINED]
print(f"{len(targets)} matière(s) combinée(s) à scinder.\n")

for s in targets:
    exam = s.get('exam', '')
    sid = s['$id']
    mine = [c for c in chaps if c.get('subjectId') == sid]
    geo = [c for c in mine if is_geo(c.get('title', ''))]
    hist = [c for c in mine if not is_geo(c.get('title', ''))]
    print(f"[{exam}] {s.get('name')} (id={sid}) — {len(mine)} chap. → Histoire={len(hist)}, Géographie={len(geo)}")
    for c in hist:
        print(f"    H  {c.get('title')}")
    for c in geo:
        print(f"    G  {c.get('title')}")

    if ('geographie', exam) in by_name_exam and norm(s.get('name', '')) == 'histoire':
        print("    (déjà scindé — saut)")
        continue
    if not APPLY:
        continue

    # 1) Renomme le doc existant en « Histoire ».
    code, out = api('PATCH', f"/collections/subjects/documents/{sid}",
                    {"data": {"name": "Histoire", "code": "Hi"}})
    if code != '200':
        print("    ! échec renommage Histoire", code, out[:140]); continue

    # 2) Crée le doc « Géographie » (mêmes réglages, ordre +1, perms identiques).
    data = {
        "name": "Géographie", "code": "Gé",
        "color": "#1E7E5A",
        "levels": s.get('levels', '') or '',
        "order": (s.get('order') or 0) + 1,
        "exam": exam, "track": s.get('track', '') or '',
        "premium": bool(s.get('premium', False)),
        "priceCredits": int(s.get('priceCredits') or 0),
        "coef": int(s.get('coef') or 0),
        "freeChapters": int(s.get('freeChapters') or 2),
    }
    perms = s.get('$permissions') or ['read("any")']
    code, out = api('POST', "/collections/subjects/documents",
                    {"documentId": "unique()", "data": data, "permissions": perms})
    if code != '201':
        print("    ! échec création Géographie", code, out[:140]); continue
    new_id = json.loads(out)['$id']

    # 3) Déplace les chapitres de géographie vers le nouveau doc.
    moved = 0
    for c in geo:
        cc, co = api('PATCH', f"/collections/chapters/documents/{c['$id']}",
                     {"data": {"subjectId": new_id}})
        if cc == '200':
            moved += 1
        else:
            print("      ! chap non déplacé", c['$id'], cc, co[:120])
    print(f"    ✓ Histoire conservé ({len(hist)} chap.) · Géographie créé id={new_id} ({moved}/{len(geo)} chap.)")

if not APPLY:
    print("\n(DRY-RUN — relance avec APPLY=1 pour écrire.)")
