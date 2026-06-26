#!/usr/bin/env python3
# Charge le contenu d'une CLASSE entière dans Appwrite (chapitres + leçons +
# quizzes), de façon générique. Chaque classe = un sous-dossier de
# tools/course_content/<classe>/ contenant :
#   - _subjects.json : {"exam":..,"level":..,"subjects":{"<code>":"<subjectId>", ...}}
#   - <code>.json    : {"code","level?","chapters":[{title,video,lesson,quiz}]}
# Pour chaque matière : supprime ses chapitres/leçons/quizzes puis recharge.
#
# Usage : APPWRITE_API_KEY="standard_xxx" python3 tools/load_course_class.py <classe>
#   ex.  APPWRITE_API_KEY=... python3 tools/load_course_class.py premiere
import os, sys, json, glob, subprocess, urllib.parse

KEY = os.environ.get('APPWRITE_API_KEY') or sys.exit('Définis APPWRITE_API_KEY')
CLS = (sys.argv[1] if len(sys.argv) > 1 else '') or sys.exit('Précise la classe (sous-dossier), ex. premiere')
EP = "https://nyc.cloud.appwrite.io/v1/databases/6a3047f8001d11d1b3c1"
H = ['-H', 'X-Appwrite-Project: 6a30463b00001375e229', '-H', f'X-Appwrite-Key: {KEY}', '-H', 'Content-Type: application/json']


def api(method, path, body=None):
    cmd = ['curl', '-s', '-X', method, EP + path] + H + (['-d', json.dumps(body)] if body is not None else []) + ['-w', '\n%{http_code}']
    r = subprocess.run(cmd, capture_output=True, text=True).stdout
    body_txt, _, code = r.rpartition('\n')
    return code, body_txt


HERE = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.join(HERE, 'course_content', CLS)
cfg = json.load(open(os.path.join(BASE, '_subjects.json')))
SUBJ = cfg['subjects']
DEFAULT_LEVEL = cfg.get('level', '')

# Attribut videoUrl sur chapters (idempotent).
api('POST', '/collections/chapters/attributes/string', {"key": "videoUrl", "size": 1024, "required": False})

now = "2026-06-22T00:00:00.000+00:00"
for f in sorted(glob.glob(os.path.join(BASE, '*.json'))):
    if os.path.basename(f) == '_subjects.json':
        continue
    d = json.load(open(f))
    sid = SUBJ.get(d['code'])
    if not sid:
        print(f"  ! {d['code']} : aucun subjectId dans _subjects.json — ignoré")
        continue
    level = d.get('level', DEFAULT_LEVEL)
    # Purge des chapitres/leçons/quizzes existants de cette matière.
    q = urllib.parse.quote(json.dumps({"method": "equal", "attribute": "subjectId", "values": [sid]}))
    q2 = urllib.parse.quote(json.dumps({"method": "limit", "values": [200]}))
    _, lst = api('GET', f"/collections/chapters/documents?queries[]={q}&queries[]={q2}")
    for c in json.loads(lst).get('documents', []):
        cid = c['$id']
        for col in ('lessons', 'quizzes', 'chapters'):
            api('DELETE', f"/collections/{col}/documents/{cid}")
    ok = 0
    for i, ch in enumerate(d['chapters']):
        cc, out = api('POST', "/collections/chapters/documents",
                      {"documentId": "unique()", "data": {"subjectId": sid, "title": ch['title'], "order": i, "level": level, "videoUrl": ch.get('video', '')}})
        if cc != '201':
            print("  ! fail", d['code'], i, cc, out[:120])
            continue
        cid = json.loads(out)['$id']
        lesson = ch.get('lesson', '')
        if lesson:
            api('POST', "/collections/lessons/documents", {"documentId": cid, "data": {"chapterId": cid, "content": lesson, "createdAt": now}})
        quiz = ch.get('quiz')
        if quiz and quiz.get('questions'):
            api('POST', "/collections/quizzes/documents", {"documentId": cid, "data": {"chapterId": cid, "content": json.dumps(quiz, ensure_ascii=False), "createdAt": now}})
        ok += 1
    print(f"  ✓ {d['code']}: {ok} chapitres")
print(f"Terminé ({CLS}).")
