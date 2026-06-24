#!/usr/bin/env python3
# Upload PDF -> bucket annales_files (read any), puis crée le doc exercise_sheets.
import sys, os, json, re
import requests

EP = "https://nyc.cloud.appwrite.io/v1"
PROJ = "6a30463b00001375e229"
DB = "6a3047f8001d11d1b3c1"
BUCKET = "annales_files"
KEY = os.environ["APPWRITE_API_KEY"]
H = {"X-Appwrite-Project": PROJ, "X-Appwrite-Key": KEY}

def slug(s):
    s = re.sub(r"[^a-zA-Z0-9_]", "_", s)
    return s[:36].strip("_")

def upload_pdf(path, file_id):
    with open(path, "rb") as f:
        files = {"file": (os.path.basename(path), f, "application/pdf")}
        data = {"fileId": file_id}
        # permissions: lecture publique
        data_list = [("fileId", file_id), ("permissions[]", 'read("any")')]
        r = requests.post(f"{EP}/storage/buckets/{BUCKET}/files",
                          headers=H, data=data_list, files=files, timeout=120)
    if r.status_code not in (200, 201):
        # peut déjà exister -> on réutilise l'id
        if r.status_code == 409:
            return file_id
        raise RuntimeError(f"upload {path}: {r.status_code} {r.text[:300]}")
    return r.json()["$id"]

def view_url(file_id):
    return f"{EP}/storage/buckets/{BUCKET}/files/{file_id}/view?project={PROJ}"

def create_sheet(doc_id, payload):
    r = requests.post(f"{EP}/databases/{DB}/collections/exercise_sheets/documents",
                      headers={**H, "Content-Type": "application/json"},
                      json={"documentId": doc_id, "data": payload,
                            "permissions": ['read("any")']}, timeout=60)
    if r.status_code == 409:
        # existe déjà -> on met à jour (reprise idempotente)
        ru = requests.patch(f"{EP}/databases/{DB}/collections/exercise_sheets/documents/{doc_id}",
                            headers={**H, "Content-Type": "application/json"},
                            json={"data": payload}, timeout=60)
        if ru.status_code in (200, 201):
            return doc_id
        raise RuntimeError(f"update sheet: {ru.status_code} {ru.text[:400]}")
    if r.status_code not in (200, 201):
        raise RuntimeError(f"create sheet: {r.status_code} {r.text[:400]}")
    return r.json()["$id"]

def main():
    idx = sys.argv[1]
    outdir = sys.argv[2]
    chapter_id = sys.argv[3]   # ex exch_mathc_02
    order = int(sys.argv[4])
    meta = json.load(open(os.path.join(outdir, f"meta{idx}.json")))
    base = f"{chapter_id}_f{order}"
    en_pdf = os.path.join(outdir, f"enonce{idx}.pdf")
    co_pdf = os.path.join(outdir, f"correction{idx}.pdf")
    en_id = upload_pdf(en_pdf, base + "_en")
    co_id = upload_pdf(co_pdf, base + "_co") if os.path.exists(co_pdf) else None
    payload = {
        "chapterId": chapter_id,
        "subject": meta["matiere"],
        "title": meta["titre"] or meta["chapter"],
        "difficulty": meta["difficulty"],
        "order": order,
        "statementPdfUrl": view_url(en_id),
    }
    if co_id:
        payload["correctionPdfUrl"] = view_url(co_id)
    doc_id = create_sheet(base, payload)
    print(json.dumps({"doc": doc_id, "enonce": view_url(en_id),
                      "correction": view_url(co_id) if co_id else None}, ensure_ascii=False))

if __name__ == "__main__":
    main()
