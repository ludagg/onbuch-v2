#!/usr/bin/env python3
# OnBuch — générateur de fiches d'exercices (NVIDIA, streaming) -> LaTeX (tectonic).
# Format à délimiteurs (pas de JSON => pas d'échappement des backslashes LaTeX).
import sys, json, os, re, time
import requests

KEY = os.environ["NVIDIA_API_KEY"]
MODEL = os.environ.get("NVIDIA_MODEL", "nvidia/nemotron-3-super-120b-a12b")
URL = "https://integrate.api.nvidia.com/v1/chat/completions"

def strip_think(t):
    t = re.sub(r"<think>.*?</think>", "", t, flags=re.S)
    if "<think>" in t and "</think>" not in t:
        t = t.split("<think>")[0]
    return t.replace("</think>", "").strip()

def call(messages, max_tokens=16000, temperature=0.45):
    # backoff sur 429 (rate limit) et 5xx
    delay = 4.0
    for attempt in range(7):
        r = requests.post(URL, headers={
            "Authorization": f"Bearer {KEY}", "Content-Type": "application/json",
            "Accept": "text/event-stream",
        }, json={"model": MODEL, "messages": messages, "temperature": temperature,
                 "top_p": 0.9, "max_tokens": max_tokens, "stream": True},
            stream=True, timeout=900)
        if r.status_code == 429 or r.status_code >= 500:
            sys.stderr.write(f"[{r.status_code} retry in {delay:.0f}s] ")
            time.sleep(delay); delay = min(delay * 1.8, 45); continue
        break
    r.raise_for_status()
    out, last = [], time.time()
    for line in r.iter_lines(decode_unicode=True):
        if not line or not line.startswith("data: "):
            continue
        data = line[6:]
        if data.strip() == "[DONE]":
            break
        try:
            j = json.loads(data)
            d = j["choices"][0]["delta"].get("content") or ""
            if d:
                out.append(d)
                if time.time() - last > 2:
                    sys.stderr.write("."); sys.stderr.flush(); last = time.time()
        except Exception:
            pass
    sys.stderr.write(" done\n")
    return "".join(out)

SYSTEM = (
    "Tu es un professeur agrégé de mathématiques au Cameroun, expert du programme "
    "MINESEC (Terminale C, Baccalauréat série C). Tu rédiges des fiches d'exercices "
    "de très haute qualité : rigoureuses, progressives, conformes au programme "
    "officiel camerounais. Tu produis du LaTeX PROPRE et COMPILABLE, SANS aucun "
    "graphique (pas de tikz ni pgfplots) — uniquement texte, maths et tableaux."
)

def prompt(chapter, difficulty, idx, focus):
    return (
        f"Génère la fiche d'exercices n°{idx} du chapitre « {chapter} » "
        f"(Mathématiques, Terminale C, Bac série C, Cameroun).\n"
        f"Difficulté globale : {difficulty}. Sous-thèmes à couvrir : {focus}.\n\n"
        "Contraintes :\n"
        "- 4 à 6 exercices numérotés, du plus simple au plus exigeant ; le dernier "
        "est un problème/situation plus complet.\n"
        "- Mathématiquement EXACT, énoncés sans ambiguïté, valeurs réalistes.\n"
        "- Correction COMPLÈTE et détaillée (chaque étape justifiée).\n"
        "- LaTeX pur. Chaque exercice commence par \\exo{Exercice 1 -- titre} "
        "(commande fournie). Sous-questions avec enumerate[label=\\alph*)]. "
        "Maths en $...$ ou \\[...\\]. Tableaux de variation/signe avec array (entre $$...$$) "
        "ou tabular.\n"
        "- INTERDIT : tikz, tikzpicture, pgfplots, axis, \\includegraphics, figure, "
        "tout tracé de courbe/graphe. Pour illustrer, décris la courbe en mots ou "
        "donne un petit tableau de valeurs — JAMAIS de graphique dessiné.\n"
        "- N'inclus NI préambule, NI \\begin{document} : seulement le corps.\n"
        "- Ferme TOUS les environnements (enumerate, itemize, array). Vérifie l'équilibre "
        "des accolades et des $. Dans un array, le nombre de & par ligne doit "
        "correspondre EXACTEMENT au nombre de colonnes déclaré.\n\n"
        "Réponds EXACTEMENT dans ce format à délimiteurs (rien avant ===TITRE===, "
        "rien après ===FIN===) :\n"
        "===TITRE===\n(titre court, 3-7 mots)\n"
        "===ENONCE===\n(corps LaTeX des énoncés)\n"
        "===CORRECTION===\n(corps LaTeX de la correction complète)\n"
        "===FIN==="
    )

def parse(raw):
    raw = strip_think(raw)
    def seg(a, b):
        m = re.search(re.escape(a) + r"(.*?)" + re.escape(b), raw, flags=re.S)
        return m.group(1).strip() if m else ""
    titre = seg("===TITRE===", "===ENONCE===")
    enonce = seg("===ENONCE===", "===CORRECTION===")
    corr = seg("===CORRECTION===", "===FIN===")
    if not corr:
        m = re.search(r"===CORRECTION===(.*)$", raw, flags=re.S)
        corr = m.group(1).strip() if m else ""
    titre = (titre.splitlines()[0].strip() if titre else "").strip("#* ").strip()
    return titre, enonce, corr

def main():
    chapter, difficulty, idx, focus, outdir = sys.argv[1:6]
    matiere, niveau = "Mathématiques", "Terminale C · Bac série C"
    sys.stderr.write(f"[gen:{MODEL.split('/')[-1]}] fiche {idx} — {chapter} ({difficulty}) ")
    raw = call([{"role": "system", "content": SYSTEM},
                {"role": "user", "content": prompt(chapter, difficulty, idx, focus)}])
    os.makedirs(outdir, exist_ok=True)
    open(os.path.join(outdir, f"raw{idx}.txt"), "w").write(raw)
    titre, enonce, corr = parse(raw)
    meta = {"titre": titre, "difficulty": difficulty, "chapter": chapter,
            "matiere": matiere, "niveau": niveau, "idx": idx, "model": MODEL,
            "enonce_len": len(enonce), "corr_len": len(corr)}
    json.dump(meta, open(os.path.join(outdir, f"meta{idx}.json"), "w"),
              ensure_ascii=False, indent=2)
    open(os.path.join(outdir, f"enonce{idx}.body.tex"), "w").write(enonce)
    open(os.path.join(outdir, f"corr{idx}.body.tex"), "w").write(corr)
    print(json.dumps(meta, ensure_ascii=False))

if __name__ == "__main__":
    main()
