#!/usr/bin/env python3
# Charge les fiches métiers (tools/data/metiers.json) dans la collection
# `metiers` d'Appwrite. Idempotent : recrée la collection à plat (supprime les
# docs existants puis réinsère). Les champs salary/testimonials sont laissés
# vides (à remplir par l'admin) sauf s'ils sont déjà présents dans le JSON.
#
# Usage : APPWRITE_API_KEY="standard_xxx" python3 tools/seed_metiers.py
import os, sys, json, subprocess

KEY = os.environ.get('APPWRITE_API_KEY') or sys.exit('Définis APPWRITE_API_KEY')
EP = "https://nyc.cloud.appwrite.io/v1/databases/6a3047f8001d11d1b3c1"
COL = "metiers"
H = ['-H', 'X-Appwrite-Project: 6a30463b00001375e229', '-H', f'X-Appwrite-Key: {KEY}', '-H', 'Content-Type: application/json']
HERE = os.path.dirname(os.path.abspath(__file__))


def api(method, path, body=None):
    cmd = ['curl', '-s', '-X', method, EP + path] + H + (['-d', json.dumps(body)] if body is not None else []) + ['-w', '\n%{http_code}']
    out = subprocess.run(cmd, capture_output=True, text=True).stdout
    body_txt, _, code = out.rpartition('\n')
    return code, body_txt


# Purge des docs existants.
_, lst = api('GET', f"/collections/{COL}/documents?queries[]=" + subprocess.run(
    ['python3', '-c', "import urllib.parse,json;print(urllib.parse.quote(json.dumps({'method':'limit','values':[200]})))"],
    capture_output=True, text=True).stdout.strip())
for d in json.loads(lst).get('documents', []):
    api('DELETE', f"/collections/{COL}/documents/{d['$id']}")

data = json.load(open(os.path.join(HERE, 'data', 'metiers.json')))
metiers = data['metiers']
ok = 0
for i, m in enumerate(metiers):
    doc = {
        'name': m.get('name', ''),
        'sector': m.get('sector', ''),
        'description': m.get('description', ''),
        'skills': m.get('skills', ''),
        'educationLevel': m.get('educationLevel', ''),
        'prospects': m.get('prospects', ''),
        'careerPath': m.get('careerPath', ''),
        'relatedFilieres': m.get('relatedFilieres', ''),
        'salary': m.get('salary', ''),
        'testimonials': m.get('testimonials', ''),
        'icon': m.get('icon', ''),
        'order': i,
        'active': True,
    }
    code, out = api('POST', f"/collections/{COL}/documents", {"documentId": "unique()", "data": doc})
    if code == '201':
        ok += 1
    else:
        print("  ! fail", m.get('name'), code, out[:120])
print(f"✓ {ok}/{len(metiers)} métiers chargés.")
