#!/usr/bin/env python3
# Orchestrateur PARALLÈLE : génère/compile/publie plusieurs fiches à la fois.
# Reprise : state.json marque ce qui est déjà publié (sauté au relancement).
import sys, json, os, subprocess, time, threading
from concurrent.futures import ThreadPoolExecutor, as_completed

BUILD = os.path.dirname(os.path.abspath(__file__))
ROOT = "/tmp/exo/out"
PLAN = json.load(open(os.path.join(BUILD, "plan.json")))
STATE_PATH = os.path.join(ROOT, "state.json")
ENV = dict(os.environ)
WORKERS = int(os.environ.get("WORKERS", "6"))
# Pool de clés NVIDIA (réparti round-robin par fiche pour contourner le 429 par clé)
KEYS = [k.strip() for k in os.environ.get(
    "NVIDIA_API_KEYS", os.environ.get("NVIDIA_API_KEY", "")).split(",") if k.strip()]

_lock = threading.Lock()
_state = json.load(open(STATE_PATH)) if os.path.exists(STATE_PATH) else {}
_counter = {"done": 0}

def save_state():
    tmp = STATE_PATH + ".tmp"
    json.dump(_state, open(tmp, "w"), ensure_ascii=False, indent=2)
    os.replace(tmp, STATE_PATH)

def log(msg):
    print(f"[{time.strftime('%H:%M:%S')}] {msg}", flush=True)

def run(cmd, timeout, env=None):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout,
                           env=env or ENV)
        return r.returncode, (r.stdout + r.stderr)
    except subprocess.TimeoutExpired:
        return 124, "TIMEOUT"

# liste plate des tâches (avec index global pour répartir les clés)
TASKS = []
for cid, data in PLAN.items():
    for i, (diff, focus) in enumerate(data["fiches"], 1):
        TASKS.append((cid, data["title"], i, diff, focus, len(TASKS)))
TOTAL = len(TASKS)

def process(task):
    cid, title, i, diff, focus, tidx = task
    env = dict(ENV)
    if KEYS:
        env["NVIDIA_API_KEY"] = KEYS[tidx % len(KEYS)]  # clé attribuée à cette fiche
    key = f"{cid}#{i}"
    with _lock:
        if _state.get(key, {}).get("uploaded"):
            _counter["done"] += 1
            return
    outdir = os.path.join(ROOT, cid)
    os.makedirs(outdir, exist_ok=True)
    t0 = time.time()
    # 1) génération
    rc, out = run(["python3", os.path.join(BUILD, "gen.py"), title, diff, str(i), focus, outdir], 900, env)
    if rc != 0:
        with _lock:
            _state[key] = {"error": "gen", "msg": out[-400:]}; save_state()
        log(f"FAIL gen {key} : {out[-200:]}"); return
    # 2) build PDF (+ réparation auto)
    rc, out = run(["python3", os.path.join(BUILD, "build_pdf.py"), str(i), outdir], 1500, env)
    res = {}
    for line in out.splitlines():
        if line.startswith("{") and '"enonce"' in line:
            try: res = json.loads(line)
            except Exception: pass
    ok_en = res.get("enonce", {}).get("ok")
    ok_co = res.get("correction", {}).get("ok")
    if not ok_en:
        with _lock:
            _state[key] = {"error": "build_enonce", "msg": out[-300:]}; save_state()
        log(f"FAIL build {key}"); return
    # 3) upload + doc
    rc, out = run(["python3", os.path.join(BUILD, "upload.py"), str(i), outdir, cid, str(i)], 300, env)
    if rc != 0:
        with _lock:
            _state[key] = {"error": "upload", "msg": out[-300:]}; save_state()
        log(f"FAIL upload {key} : {out[-200:]}"); return
    doc = {}
    for line in out.splitlines():
        if line.startswith("{"):
            try: doc = json.loads(line)
            except Exception: pass
    secs = round(time.time() - t0, 1)
    with _lock:
        _counter["done"] += 1
        n = _counter["done"]
        _state[key] = {"uploaded": True, "doc": doc.get("doc"),
                       "correction": bool(ok_co), "secs": secs}
        save_state()
    log(f"OK {n}/{TOTAL} {key} — {title} f{i} ({diff}) en {secs}s"
        + ("" if ok_co else " [SANS correction]"))

def main():
    log(f"=== DÉMARRAGE parallèle : {WORKERS} workers, {TOTAL} fiches ===")
    with ThreadPoolExecutor(max_workers=WORKERS) as ex:
        futs = [ex.submit(process, t) for t in TASKS]
        for f in as_completed(futs):
            try: f.result()
            except Exception as e: log(f"WORKER EXC: {e}")
    with _lock:
        ok = len([k for k, v in _state.items() if v.get("uploaded")])
        nocorr = [k for k, v in _state.items() if v.get("uploaded") and v.get("correction") is False]
        errs = [k for k, v in _state.items() if v.get("error")]
    log(f"=== TERMINÉ : {ok}/{TOTAL} publiées | sans correction: {len(nocorr)} {nocorr} | erreurs: {len(errs)} {errs} ===")

if __name__ == "__main__":
    main()
