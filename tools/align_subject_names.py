#!/usr/bin/env python3
# Aligne les NOMS des matières (collection `subjects`, contenu des cours) sur la
# taxonomie canonique des examens (`lib/data/exam_taxonomy.dart`) — la même qui
# pilote les Annales/ressources. Objectif : que la matière d'un cours porte
# EXACTEMENT le même libellé que dans les ressources (« même sens »).
#
# Le seul écart historique : le contenu des cours utilise « Histoire-Géo »
# (combiné) alors que la taxonomie listait « Histoire » + « Géographie »
# séparés. On unifie tout sur « Histoire-Géographie » (1 matière, comme au
# Cameroun) : la taxonomie est corrigée côté app, ce script aligne la base.
#
# Idempotent. Lancer en DRY d'abord (défaut), puis avec APPLY=1 pour écrire.
#   APPWRITE_API_KEY="standard_xxx" python3 tools/align_subject_names.py        # dry-run
#   APPWRITE_API_KEY="standard_xxx" APPLY=1 python3 tools/align_subject_names.py # applique
import os, sys, json, subprocess, urllib.parse

KEY = os.environ.get('APPWRITE_API_KEY') or sys.exit('Définis APPWRITE_API_KEY')
APPLY = os.environ.get('APPLY') == '1'
EP = "https://nyc.cloud.appwrite.io/v1/databases/6a3047f8001d11d1b3c1"
H = ['-H', 'X-Appwrite-Project: 6a30463b00001375e229', '-H', f'X-Appwrite-Key: {KEY}', '-H', 'Content-Type: application/json']

# Renommages exacts (nom actuel -> nom canonique taxonomie). Insensible aux
# variantes simples : on compare en .strip(). Étendre ici si d'autres écarts.
RENAME = {
    'Histoire-Géo': 'Histoire-Géographie',
    'Histoire-Geo': 'Histoire-Géographie',
    'Hist-Géo': 'Histoire-Géographie',
    'Histoire Géographie': 'Histoire-Géographie',
}


def api(method, path, body=None):
    cmd = ['curl', '-s', '-X', method, EP + path] + H + (['-d', json.dumps(body)] if body is not None else []) + ['-w', '\n%{http_code}']
    out = subprocess.run(cmd, capture_output=True, text=True).stdout
    b, _, code = out.rpartition('\n')
    return code, b


def list_all(col):
    docs, offset = [], 0
    while True:
        qs = [
            urllib.parse.quote(json.dumps({"method": "limit", "values": [100]})),
            urllib.parse.quote(json.dumps({"method": "offset", "values": [offset]})),
        ]
        _, b = api('GET', f"/collections/{col}/documents?queries[]={qs[0]}&queries[]={qs[1]}")
        page = json.loads(b).get('documents', [])
        docs += page
        if len(page) < 100:
            break
        offset += 100
    return docs


subs = list_all('subjects')
print(f"{len(subs)} matières (subjects) :")
for s in sorted(subs, key=lambda x: (x.get('exam') or '', x.get('name') or '')):
    print(f"  · {s.get('name'):<24} exam={s.get('exam') or '-':<14} track={s.get('track') or '-'}")

todo = [(s['$id'], s.get('name', ''), RENAME[s.get('name', '').strip()])
        for s in subs if s.get('name', '').strip() in RENAME]
print(f"\n{len(todo)} à renommer :")
for sid, old, new in todo:
    print(f"  {old!r} -> {new!r}")

if not APPLY:
    print("\n(DRY-RUN — relance avec APPLY=1 pour écrire.)")
    sys.exit(0)

ok = 0
for sid, old, new in todo:
    code, out = api('PATCH', f"/collections/subjects/documents/{sid}", {"data": {"name": new}})
    if code == '200':
        ok += 1
    else:
        print("  ! fail", sid, code, out[:120])
print(f"\n✓ {ok}/{len(todo)} renommées.")
