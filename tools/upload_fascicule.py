#!/usr/bin/env python3
"""Publie un fascicule (livre PDF) OnBuch dans la collection `fascicules`.

Téléverse le PDF (et une couverture) dans le bucket `annales_files`, puis crée
le document `fascicules`. Si aucune couverture n'est fournie, la 1re page du PDF
est rendue en JPG (nécessite `pdftoppm`, paquet poppler-utils).

Usage :
  APPWRITE_API_KEY="standard_xxx" python3 tools/upload_fascicule.py \
      --pdf chemin/vers/livre.pdf \
      --title "Mathématiques — Terminale C" \
      --subject "Mathématiques" --level "Terminale C" \
      --exam "Baccalauréat" --track "C,D,E,TI" \
      --author "L'équipe OnBuch, dirigée par Ludovic Aggaï N." \
      [--cover chemin/vers/couverture.jpg] [--order 1] [--premium]

Clé API **serveur** (scope databases.write + files.write).
"""
import argparse, json, os, subprocess, sys, tempfile, time, uuid
import urllib.request

EP = os.environ.get("APPWRITE_ENDPOINT", "https://nyc.cloud.appwrite.io/v1")
PROJ = os.environ.get("APPWRITE_PROJECT", "6a30463b00001375e229")
DB = os.environ.get("APPWRITE_DATABASE", "6a3047f8001d11d1b3c1")
BUCKET = os.environ.get("APPWRITE_BUCKET", "annales_files")
KEY = os.environ.get("APPWRITE_API_KEY")
COL = "fascicules"


def _boundary_upload(path, mime):
    """Multipart upload via urllib (pas de dépendance requests)."""
    fid = uuid.uuid4().hex[:36]
    boundary = "----onbuch" + uuid.uuid4().hex
    with open(path, "rb") as f:
        filedata = f.read()
    parts = []

    def field(name, value):
        parts.append(("--" + boundary).encode())
        parts.append(('Content-Disposition: form-data; name="%s"' % name).encode())
        parts.append(b"")
        parts.append(value.encode())

    field("fileId", fid)
    field("permissions[]", 'read("any")')
    parts.append(("--" + boundary).encode())
    parts.append(('Content-Disposition: form-data; name="file"; filename="%s"'
                  % os.path.basename(path)).encode())
    parts.append(("Content-Type: %s" % mime).encode())
    parts.append(b"")
    parts.append(filedata)
    parts.append(("--" + boundary + "--").encode())
    parts.append(b"")
    body = b"\r\n".join(parts)

    req = urllib.request.Request(
        f"{EP}/storage/buckets/{BUCKET}/files", data=body, method="POST",
        headers={
            "X-Appwrite-Project": PROJ, "X-Appwrite-Key": KEY,
            "Content-Type": "multipart/form-data; boundary=" + boundary,
        })
    urllib.request.urlopen(req).read()
    return f"{EP}/storage/buckets/{BUCKET}/files/{fid}/view?project={PROJ}"


def _pdf_pages(path):
    try:
        out = subprocess.check_output(["pdfinfo", path], text=True)
        for line in out.splitlines():
            if line.lower().startswith("pages:"):
                return int(line.split(":")[1].strip())
    except Exception:
        pass
    return 0


def _render_cover(pdf):
    tmp = tempfile.mkdtemp()
    base = os.path.join(tmp, "cover")
    subprocess.check_call(["pdftoppm", "-jpeg", "-r", "150", "-singlefile",
                           "-f", "1", "-l", "1", pdf, base])
    return base + ".jpg"


def main():
    if not KEY:
        sys.exit("Définis APPWRITE_API_KEY (clé serveur).")
    ap = argparse.ArgumentParser()
    ap.add_argument("--pdf", required=True)
    ap.add_argument("--cover")
    ap.add_argument("--title", required=True)
    ap.add_argument("--subject", default="")
    ap.add_argument("--level", default="")
    ap.add_argument("--exam", default="")
    ap.add_argument("--track", default="")
    ap.add_argument("--description", default="")
    ap.add_argument("--author", default="L'équipe OnBuch, dirigée par Ludovic Aggaï N.")
    ap.add_argument("--pages", type=int, default=0)
    ap.add_argument("--order", type=int, default=0)
    ap.add_argument("--premium", action="store_true")
    a = ap.parse_args()

    pages = a.pages or _pdf_pages(a.pdf)
    print("→ Upload du PDF…")
    pdf_url = _boundary_upload(a.pdf, "application/pdf")

    cover = a.cover
    if not cover:
        try:
            print("→ Rendu de la couverture (1re page)…")
            cover = _render_cover(a.pdf)
        except Exception as e:
            print("  (couverture auto impossible : %s — couverture par défaut)" % e)
            cover = None
    cover_url = ""
    if cover:
        print("→ Upload de la couverture…")
        cover_url = _boundary_upload(cover, "image/jpeg")

    doc = {
        "title": a.title, "subject": a.subject, "level": a.level,
        "exam": a.exam, "track": a.track, "description": a.description,
        "coverUrl": cover_url, "pdfUrl": pdf_url, "author": a.author,
        "pages": pages, "premium": a.premium, "order": a.order, "active": True,
    }
    did = uuid.uuid4().hex[:36]
    payload = json.dumps({"documentId": did, "data": doc,
                          "permissions": ['read("any")']}).encode()
    # l'attribut peut être en cours de création : on retente quelques fois
    for attempt in range(8):
        req = urllib.request.Request(
            f"{EP}/databases/{DB}/collections/{COL}/documents", data=payload,
            method="POST", headers={
                "X-Appwrite-Project": PROJ, "X-Appwrite-Key": KEY,
                "Content-Type": "application/json"})
        try:
            urllib.request.urlopen(req).read()
            print("✅ Fascicule publié :", did, "(%d pages)" % pages)
            return
        except urllib.error.HTTPError as e:
            if attempt < 7:
                print("  retry…", e.code); time.sleep(4)
            else:
                sys.exit("Échec création doc : %s\n%s" % (e.code, e.read().decode()))


if __name__ == "__main__":
    main()
