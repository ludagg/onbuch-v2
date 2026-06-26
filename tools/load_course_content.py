#!/usr/bin/env python3
# Charge le contenu des cours (tools/course_content/*.json) dans Appwrite :
# pour chaque matière (subjects), remplace ses chapitres + leçons + quizzes.
# Contenu généré (MINESEC, Terminale, adapté aux séries camerounaises).
#
# Usage : APPWRITE_API_KEY="standard_xxx" python3 tools/load_course_content.py
import os, sys, json, glob, subprocess, urllib.parse
KEY=os.environ.get('APPWRITE_API_KEY') or sys.exit('Définis APPWRITE_API_KEY')
EP="https://nyc.cloud.appwrite.io/v1/databases/6a3047f8001d11d1b3c1"
H=['-H','X-Appwrite-Project: 6a30463b00001375e229','-H',f'X-Appwrite-Key: {KEY}','-H','Content-Type: application/json']
# code matière -> $id du document `subjects`
SUBJ={'Ma':'6a316d67950013025e89','PC':'6a316d67b096b3cb24b0','SV':'6a316d67d08503fd815e',
      'Ph':'6a316d67e3a839325bba','Fr':'6a316d680e40da8b7ec8','An':'6a316d6824c6f38a6e3b','HG':'6a316d6847b4e14d8ce5'}
def api(method, path, body=None):
    cmd=['curl','-s','-X',method,EP+path]+H+(['-d',json.dumps(body)] if body is not None else [])+['-w','\n%{http_code}']
    r=subprocess.run(cmd,capture_output=True,text=True).stdout
    return r.rsplit('\n',1)[-1], r.rsplit('\n',1)[0]
HERE=os.path.dirname(os.path.abspath(__file__))
# S'assure que l'attribut videoUrl existe sur `chapters` (idempotent, 409 ignoré).
api('POST','/collections/chapters/attributes/string',{"key":"videoUrl","size":1024,"required":False})
for f in sorted(glob.glob(os.path.join(HERE,'course_content','*.json'))):
    d=json.load(open(f)); sid=SUBJ.get(d['code'])
    if not sid: continue
    q=urllib.parse.quote(json.dumps({"method":"equal","attribute":"subjectId","values":[sid]}))
    q2=urllib.parse.quote(json.dumps({"method":"limit","values":[100]}))
    _,lst=api('GET',f"/collections/chapters/documents?queries[]={q}&queries[]={q2}")
    for c in json.loads(lst).get('documents',[]):
        cid=c['$id']
        for col in ('lessons','quizzes','chapters'): api('DELETE',f"/collections/{col}/documents/{cid}")
    now="2026-06-22T00:00:00.000+00:00"; ok=0
    level=d.get('level','Terminale')
    for i,ch in enumerate(d['chapters']):
        cc,out=api('POST',"/collections/chapters/documents",{"documentId":"unique()","data":{"subjectId":sid,"title":ch['title'],"order":i,"level":level,"videoUrl":ch.get('video','')}})
        if cc!='201': print("  ! fail",d['code'],i,cc); continue
        cid=json.loads(out)['$id']
        api('POST',"/collections/lessons/documents",{"documentId":cid,"data":{"chapterId":cid,"content":ch['lesson'],"createdAt":now}})
        api('POST',"/collections/quizzes/documents",{"documentId":cid,"data":{"chapterId":cid,"content":json.dumps(ch['quiz'],ensure_ascii=False),"createdAt":now}})
        ok+=1
    print(f"  ✓ {d['code']}: {ok} chapitres")
print("Terminé.")
