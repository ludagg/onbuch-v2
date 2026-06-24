#!/usr/bin/env python3
# Assemble énoncé + correction en .tex complets, compile via tectonic.
# Boucle de réparation auto : si la compilation échoue, on demande au modèle de
# corriger le corps LaTeX (en lui donnant l'erreur tectonic), puis on recompile.
import sys, os, json, subprocess, re, time
import requests

BUILD = os.path.dirname(os.path.abspath(__file__))
KEY = os.environ.get("NVIDIA_API_KEY", "")
REPAIR_MODEL = os.environ.get("REPAIR_MODEL", "nvidia/nemotron-3-super-120b-a12b")
URL = "https://integrate.api.nvidia.com/v1/chat/completions"
MAX_FIX = int(os.environ.get("MAX_FIX", "3"))

def read(p):
    with open(p) as f:
        return f.read()

def latex_escape_text(s):
    return s.replace("&", r"\&").replace("%", r"\%").replace("_", r"\_").replace("#", r"\#")

def assemble(meta, body, kind):
    preamble = read(os.path.join(BUILD, "preamble.tex"))
    defs = ("\\newcommand{\\DOCMATIERE}{" + latex_escape_text(meta["matiere"]) + "}\n"
            "\\newcommand{\\DOCNIVEAU}{" + latex_escape_text(meta["niveau"]) + "}\n")
    titre = latex_escape_text(meta["titre"] or meta["chapter"])
    chap = latex_escape_text(meta["chapter"])
    diff = latex_escape_text(meta["difficulty"])
    if kind == "enonce":
        header = "\\fichetitre{" + titre + "}{" + chap + "}{" + diff + "}\n"
        content = header + "\n" + body
    else:
        header = "\\fichetitre{" + titre + "}{Correction · " + chap + "}{" + diff + "}\n"
        content = header + "\n\\begin{correction}\n" + body + "\n\\end{correction}\n"
    return preamble + "\n" + defs + "\\begin{document}\n" + content + "\n\\end{document}\n"

def compile_tex(texpath):
    outdir = os.path.dirname(texpath)
    pdf = texpath[:-4] + ".pdf"
    if os.path.exists(pdf):
        os.remove(pdf)
    r = subprocess.run(["tectonic", "-X", "compile", "--outdir", outdir, "--keep-logs",
                        "-Z", "shell-escape", texpath],
                       capture_output=True, text=True, timeout=300)
    log = ""
    logp = texpath[:-4] + ".log"
    if os.path.exists(logp):
        log = read(logp)
    combined = log + "\n" + r.stdout + "\n" + r.stderr
    # tectonic peut produire un PDF MALGRÉ une erreur récupérable (=> contenu cassé).
    # On considère donc qu'il y a échec dès qu'une erreur LaTeX apparaît dans le log.
    has_error = bool(re.search(r"^!|error:|Extra alignment|Missing|Undefined control|"
                               r"Runaway argument|Misplaced|Too many|paragraph ended",
                               combined, flags=re.M))
    ok = os.path.exists(pdf) and not has_error
    return ok, combined, pdf

def error_tail(log):
    # extrait les lignes d'erreur LaTeX utiles (+ contexte)
    lines = log.splitlines()
    out = []
    for i, l in enumerate(lines):
        if (l.strip().startswith("!") or "error:" in l.lower() or l.startswith("l.")
                or re.search(r"Extra alignment|Missing|Undefined control|Runaway|"
                             r"Misplaced|Too many|paragraph ended", l)):
            out.extend(lines[max(0, i - 1):i + 3])
    seen, ded = set(), []
    for l in out:
        if l not in seen:
            seen.add(l); ded.append(l)
    ctx = ded[:25] if ded else lines[-25:]
    return "\n".join(ctx)[:2800]

def repair(body, errlog, kind):
    if not KEY:
        return None
    sys_msg = ("Tu es un expert LaTeX. On te donne un fragment de corps LaTeX (sans "
               "préambule) qui NE COMPILE PAS avec tectonic/XeLaTeX, et l'erreur. "
               "Corrige UNIQUEMENT les erreurs de syntaxe LaTeX (accolades, $, "
               "environnements non fermés, commandes invalides) SANS changer le sens "
               "mathématique ni le contenu. Packages dispo : amsmath, amssymb, tikz, "
               "pgfplots, enumitem, tcolorbox. Commande \\exo{...} disponible. "
               "Réponds UNIQUEMENT avec le corps LaTeX corrigé entre les marqueurs "
               "<<<TEX>>> et <<<END>>>, rien d'autre.")
    user = (f"Erreur tectonic :\n{errlog}\n\nCorps LaTeX à corriger :\n<<<TEX>>>\n{body}\n<<<END>>>")
    try:
        delay = 4.0
        for _ in range(6):
            r = requests.post(URL, headers={"Authorization": f"Bearer {KEY}",
                              "Content-Type": "application/json"},
                              json={"model": REPAIR_MODEL,
                                    "messages": [{"role": "system", "content": sys_msg},
                                                 {"role": "user", "content": user}],
                                    "temperature": 0.1, "max_tokens": 16000},
                              timeout=600)
            if r.status_code == 429 or r.status_code >= 500:
                time.sleep(delay); delay = min(delay * 1.8, 45); continue
            break
        r.raise_for_status()
        txt = r.json()["choices"][0]["message"]["content"]
        txt = re.sub(r"<think>.*?</think>", "", txt, flags=re.S)
        m = re.search(r"<<<TEX>>>(.*?)<<<END>>>", txt, flags=re.S)
        fixed = (m.group(1) if m else txt).strip()
        return fixed or None
    except Exception as e:
        sys.stderr.write(f"[repair error] {e}\n")
        return None

def build_one(meta, body, kind, idx, outdir):
    texpath = os.path.join(outdir, f"{kind}{idx}.tex")
    base_len = len(body)
    for attempt in range(MAX_FIX + 1):
        tex = assemble(meta, body, kind)
        open(texpath, "w").write(tex)
        ok, log, pdf = compile_tex(texpath)
        if ok:
            return True, pdf, attempt
        tail = error_tail(log)
        sys.stderr.write(f"[{kind}{idx}] échec compile (essai {attempt+1}) : {tail.splitlines()[0] if tail else '?'}\n")
        if attempt >= MAX_FIX:
            open(os.path.join(outdir, f"{kind}{idx}.err.log"), "w").write(log)
            return False, None, attempt
        fixed = repair(body, tail, kind)
        # garde-fou : une réparation qui gonfle anormalement (>1.6x la taille
        # initiale) ou qui devient énorme (>20k) est rejetée -> on abandonne vite.
        if not fixed or len(fixed) > max(20000, int(base_len * 1.6)):
            open(os.path.join(outdir, f"{kind}{idx}.err.log"), "w").write(log)
            return False, None, attempt
        body = fixed
        open(os.path.join(outdir, f"{kind}{idx}.body.tex"), "w").write(body)  # garde la version réparée
    return False, None, MAX_FIX

def main():
    idx, outdir = sys.argv[1], sys.argv[2]
    meta = json.load(open(os.path.join(outdir, f"meta{idx}.json")))
    results = {}
    for kind, bodyfile in [("enonce", f"enonce{idx}.body.tex"), ("correction", f"corr{idx}.body.tex")]:
        body = read(os.path.join(outdir, bodyfile))
        ok, pdf, tries = build_one(meta, body, kind, idx, outdir)
        results[kind] = {"ok": ok, "pdf": pdf, "fixes": tries}
        print(f"[{'OK' if ok else 'FAIL'}] {kind} (réparations: {tries}) -> {pdf or 'échec'}")
    print(json.dumps(results))

if __name__ == "__main__":
    main()
