# OnBuch — Bot Telegram crédits (@OnBuchCreditsBot)

Webhook serverless (Vercel) qui gère l'achat de crédits par Mobile Money
(Orange / MTN) avec validation admin, puis émet un **code** à saisir dans l'app.

## Déploiement
```
cd telegram-bot
npx vercel deploy --prod --yes --scope <team> --token <VERCEL_TOKEN>
```

## Variables d'environnement (Vercel → Settings → Environment Variables)
**Aucune valeur de secret n'est versionnée.**

| Variable | Rôle |
|---|---|
| `TELEGRAM_BOT_TOKEN` | token @BotFather du bot |
| `ADMIN_CHAT_ID` | ID du groupe admin (validation ✅/❌) ; le bot doit y être membre |
| `TG_SECRET` | secret du webhook (en-tête `X-Telegram-Bot-Api-Secret-Token`) |
| `APPWRITE_ENDPOINT` `APPWRITE_PROJECT` `APPWRITE_DB` | config Appwrite |
| `APPWRITE_API_KEY` | clé serveur (scope databases.write) |
| `MTN_NUMBER` `MTN_NAME` `ORANGE_NUMBER` `ORANGE_NAME` | numéros de dépôt (optionnel) |

## Enregistrer le webhook
```
curl "https://api.telegram.org/bot<TOKEN>/setWebhook" \
  -d url="https://<deploiement>.vercel.app/api/telegram" \
  -d secret_token="<TG_SECRET>"
```

## Convertisseur FCFA → crédits
Tranches marginales reproduisant `100→10, 500→60, 1000→150` ; meilleur taux au‑delà.
Source unique : `creditsFor()` (bot) ; le crédit figé est stocké à la commande et
réappliqué tel quel par la fonction `redeem-code`.
