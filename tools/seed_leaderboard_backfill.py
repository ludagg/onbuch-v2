#!/usr/bin/env python3
# Pré-remplit la collection `leaderboard` à partir des données de jeu existantes
# (collection `gamification`) + des noms (`users`). Utile pour ne pas lancer
# avec un classement vide : chaque élève qui a déjà de l'XP apparaît au
# classement NATIONAL (par XP total), même s'il n'a pas encore mis à jour l'app.
#
# weeklyXp est mis à 0 (non mesurable côté serveur) ; il deviendra réel dès que
# l'app de l'élève se met à jour et publie son entrée.
#
# Idempotent : documentId = uid (créé ou mis à jour). Permissions : lecture
# publique + écriture par le propriétaire (pour que son app puisse re-publier).
#
# Usage : APPWRITE_API_KEY="standard_xxx" python3 tools/seed_leaderboard_backfill.py
import os, sys, json, subprocess, urllib.parse

KEY = os.environ.get('APPWRITE_API_KEY') or sys.exit('Définis APPWRITE_API_KEY')
EP = "https://nyc.cloud.appwrite.io/v1/databases/6a3047f8001d11d1b3c1"
H = ['-H', 'X-Appwrite-Project: 6a30463b00001375e229', '-H', f'X-Appwrite-Key: {KEY}', '-H', 'Content-Type: application/json']

LEAGUES = [('Bronze', 1), ('Argent', 3), ('Or', 5), ('Saphir', 8), ('Rubis', 12), ('Diamant', 17)]
WEEK_ID = "2026-06-22"  # lundi de la semaine courante


def api(method, path, body=None):
    cmd = ['curl', '-s', '-X', method, EP + path] + H + (['-d', json.dumps(body)] if body is not None else []) + ['-w', '\n%{http_code}']
    out = subprocess.run(cmd, capture_output=True, text=True).stdout
    b, _, code = out.rpartition('\n')
    return code, b


def level_of(xp):
    l = 1
    while 50 * l * (l + 1) <= xp:
        l += 1
    return l


def league_of(level):
    res = 'Bronze'
    for name, minl in LEAGUES:
        if level >= minl:
            res = name
    return res


def list_all(col):
    q = urllib.parse.quote(json.dumps({"method": "limit", "values": [100]}))
    _, b = api('GET', f"/collections/{col}/documents?queries[]={q}")
    return json.loads(b).get('documents', [])


# Noms depuis `users`.
names = {}
for u in list_all('users'):
    fn = (u.get('firstName') or '').strip()
    ln = (u.get('lastName') or '').strip()
    nm = (fn + ' ' + ln).strip()
    names[u['$id']] = nm if nm else 'Élève'

ok = 0
for g in list_all('gamification'):
    uid = g['$id']
    xp = int(g.get('xp') or 0)
    if xp <= 0:
        continue
    lvl = level_of(xp)
    data = {
        'uid': uid,
        'name': names.get(uid, 'Élève'),
        'level': lvl,
        'xp': xp,
        'weeklyXp': 0,
        'league': league_of(lvl),
        'weekId': WEEK_ID,
        'updatedAt': '2026-06-27T00:00:00.000+00:00',
    }
    # update si existe, sinon create avec permissions propriétaire.
    code, _ = api('PATCH', f"/collections/leaderboard/documents/{uid}", {"data": data})
    if code == '404':
        perms = [f'read("any")', f'update("user:{uid}")', f'delete("user:{uid}")']
        code, out = api('POST', "/collections/leaderboard/documents",
                        {"documentId": uid, "data": data, "permissions": perms})
        if code != '201':
            print("  ! fail", uid, code, out[:120])
            continue
    ok += 1
print(f"✓ {ok} élèves au classement (par XP total).")
