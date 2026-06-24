#!/usr/bin/env python3
# Publieur générique d'une fiche rédigée à la main (physique OU chimie).
# Récupère matière + titre du chapitre depuis Appwrite. Crée meta, compile, upload.
# Usage: pub.py <chapter_id> <idx> <difficulty> "<titre fiche>"
import sys, os, json, subprocess, requests

BUILD = os.path.dirname(os.path.abspath(__file__))
ROOT = "/tmp/exo/out"
EP="https://nyc.cloud.appwrite.io/v1"; PROJ="6a30463b00001375e229"; DB="6a3047f8001d11d1b3c1"
KEY=os.environ["APPWRITE_API_KEY"]
H={"X-Appwrite-Project":PROJ,"X-Appwrite-Key":KEY}

def chapter_info(cid):
    r=requests.get(f"{EP}/databases/{DB}/collections/exercise_chapters/documents/{cid}",headers=H,timeout=30)
    d=r.json()
    return d.get("subject","Physique"), d.get("title","Chapitre")

def main():
    cid, idx, diff, titre = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
    outdir=os.path.join(ROOT,cid); os.makedirs(outdir,exist_ok=True)
    subject, chtitle = chapter_info(cid)
    meta={"titre":titre,"difficulty":diff,"chapter":chtitle,"matiere":subject,
          "niveau":"Terminale · Bac ESG (C·D·E·TI)","idx":idx}
    json.dump(meta,open(os.path.join(outdir,f"meta{idx}.json"),"w"),ensure_ascii=False,indent=2)
    env=dict(os.environ)
    b=subprocess.run(["python3",os.path.join(BUILD,"build_pdf.py"),idx,outdir],capture_output=True,text=True,env=env)
    for line in b.stdout.splitlines():
        if line.startswith("[OK]") or line.startswith("[FAIL]"): print(line)
    if "[FAIL]" in b.stdout:
        print("STDERR:",b.stderr[-400:]); return
    u=subprocess.run(["python3",os.path.join(BUILD,"upload.py"),idx,outdir,cid,idx],capture_output=True,text=True,env=env)
    print(u.stdout.strip() or u.stderr[-300:])

if __name__=="__main__":
    main()
