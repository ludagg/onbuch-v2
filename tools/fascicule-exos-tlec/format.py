#!/usr/bin/env python3
"""Prépare le contenu brut de la banque « 1000 exercices » pour la mise en page
deux colonnes (preamble.tex). 3 transformations mécaniques, sûres, qui ne
changent PAS la substance mathématique :

  1. $$ ... $$  ->  \\[ ... \\]      (display moderne, auto-réductible à la colonne)
  2. un \\tag isolé dans un \\[..\\] -> \\qquad(...)   (incompatible avec l'inline-math)
  3. maths inline >= 40 caractères -> \\fitmath{...}  (réduit seulement si trop large)

Le scanner respecte les commentaires % et les échappements \\$, \\%.

Usage :  python3 format.py  contenu_brut.tex  maitre.tex
"""
import sys

TH = 40  # seuil (en caractères) au-delà duquel une maths inline est enveloppée

def transform(s: str) -> str:
    s = s.replace("= 0. \\tag{$\\star$}", "= 0. \\qquad(\\star)")
    n = len(s); i = 0; out = []
    def comment(i):
        j = s.find('\n', i); j = n if j < 0 else j + 1
        return s[i:j], j
    while i < n:
        c = s[i]
        if c == '\\' and i + 1 < n:
            out.append(s[i:i+2]); i += 2; continue
        if c == '%':
            seg, i = comment(i); out.append(seg); continue
        if c == '$':
            if i + 1 < n and s[i+1] == '$':            # display $$ ... $$
                i += 2; buf = []
                while i < n:
                    if s[i] == '\\' and i + 1 < n: buf.append(s[i:i+2]); i += 2; continue
                    if s[i] == '%': seg, i = comment(i); buf.append(seg); continue
                    if s[i] == '$' and i + 1 < n and s[i+1] == '$': i += 2; break
                    buf.append(s[i]); i += 1
                out.append('\\[' + ''.join(buf) + '\\]'); continue
            else:                                       # inline $ ... $
                i += 1; buf = []
                while i < n:
                    if s[i] == '\\' and i + 1 < n: buf.append(s[i:i+2]); i += 2; continue
                    if s[i] == '%': seg, i = comment(i); buf.append(seg); continue
                    if s[i] == '$': i += 1; break
                    buf.append(s[i]); i += 1
                content = ''.join(buf)
                out.append('\\fitmath{' + content + '}' if len(content) >= TH else '$' + content + '$')
                continue
        out.append(c); i += 1
    return ''.join(out)

if __name__ == "__main__":
    src, dst = sys.argv[1], sys.argv[2]
    open(dst, "w", encoding="utf-8").write(transform(open(src, encoding="utf-8").read()))
    print(f"OK -> {dst}")
