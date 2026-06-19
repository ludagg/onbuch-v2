// verify-purchase — vérifie un achat Google Play Billing puis crédite le compte.
//
// Flux : l'app (BillingService) appelle cette fonction en SYNCHRONE avec
// { productId, purchaseToken, packageName }. La fonction :
//   1. identifie l'utilisateur via l'en-tête x-appwrite-user-id ;
//   2. interroge l'API Google Play Developer (Android Publisher) pour vérifier
//      que l'achat est valide (purchaseState = 0) ;
//   3. crédite `tutor_quota/{userId}` du nombre de crédits du produit ;
//   4. enregistre le reçu (idempotence) pour ne pas créditer deux fois.
//
// Variables d'environnement à définir sur la fonction :
//   - GOOGLE_SERVICE_ACCOUNT : JSON du compte de service Google (accès
//     Android Publisher), en une seule ligne.
//   - APPWRITE_API_KEY : clé API serveur Appwrite (scope databases.write).
//   - DATABASE_ID (optionnel, défaut ci-dessous)
// Appwrite injecte APPWRITE_FUNCTION_API_ENDPOINT et APPWRITE_FUNCTION_PROJECT_ID.

import { Client, Databases, ID } from 'node-appwrite';
import { GoogleAuth } from 'google-auth-library';

// Produit Play -> crédits accordés (doit refléter BillingService.creditProducts).
const CREDIT_PRODUCTS = {
  ob_credits_5: 5,
  ob_credits_15: 15,
  ob_credits_40: 40,
};

const DATABASE_ID = process.env.DATABASE_ID || '6a3047f8001d11d1b3c1';
const QUOTA_COLLECTION = 'tutor_quota';
const RECEIPTS_COLLECTION = 'purchase_receipts';

export default async ({ req, res, log, error }) => {
  const fail = (msg, code = 200) => res.json({ ok: false, error: msg }, code);

  let payload;
  try {
    payload = typeof req.body === 'string' ? JSON.parse(req.body || '{}') : (req.body || {});
  } catch {
    return fail('Corps de requête invalide.', 400);
  }

  const { productId, purchaseToken, packageName } = payload;
  if (!productId || !purchaseToken || !packageName) {
    return fail('Paramètres manquants.', 400);
  }
  const credits = CREDIT_PRODUCTS[productId];
  if (!credits) return fail('Produit inconnu.', 400);

  const userId = req.headers['x-appwrite-user-id'];
  if (!userId) return fail('Utilisateur non authentifié.', 401);

  // 1) Vérification auprès de Google Play.
  let purchase;
  try {
    const auth = new GoogleAuth({
      credentials: JSON.parse(process.env.GOOGLE_SERVICE_ACCOUNT),
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });
    const token = await auth.getAccessToken();
    const url =
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
      `${encodeURIComponent(packageName)}/purchases/products/` +
      `${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;
    const r = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
    if (!r.ok) {
      error(`Google verify HTTP ${r.status}`);
      return fail('Reçu refusé par Google Play.');
    }
    purchase = await r.json();
  } catch (e) {
    error(`Google verify error: ${e.message}`);
    return fail('Vérification Google impossible.');
  }

  // purchaseState: 0 = acheté, 1 = annulé, 2 = en attente.
  if (purchase.purchaseState !== 0) return fail('Achat non finalisé.');

  // 2) Appwrite (clé serveur).
  const client = new Client()
    .setEndpoint(process.env.APPWRITE_FUNCTION_API_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);
  const db = new Databases(client);

  // 3) Idempotence : un reçu (orderId) ne crédite qu'une fois.
  const receiptId = (purchase.orderId || purchaseToken).replace(/[^a-zA-Z0-9_-]/g, '').slice(0, 36) || ID.unique();
  try {
    await db.createDocument(DATABASE_ID, RECEIPTS_COLLECTION, receiptId, {
      userId,
      productId,
      credits,
      createdAt: new Date().toISOString(),
    });
  } catch (e) {
    // 409 = déjà traité → on renvoie ok sans recréditer.
    if (String(e.code) === '409' || e.code === 409) {
      return res.json({ ok: true, credits: 0, alreadyProcessed: true });
    }
    // Si la collection n'existe pas, on log et on continue (idempotence dégradée).
    error(`Receipt store error: ${e.message}`);
  }

  // 4) Créditer tutor_quota/{userId}.
  try {
    let current = 0;
    try {
      const doc = await db.getDocument(DATABASE_ID, QUOTA_COLLECTION, userId);
      current = Number(doc.credits || 0);
      await db.updateDocument(DATABASE_ID, QUOTA_COLLECTION, userId, { credits: current + credits });
    } catch (e) {
      if (String(e.code) === '404' || e.code === 404) {
        await db.createDocument(DATABASE_ID, QUOTA_COLLECTION, userId, {
          credits, freeUsedToday: 0, freeResetDate: '',
        });
      } else {
        throw e;
      }
    }
  } catch (e) {
    error(`Credit grant error: ${e.message}`);
    return fail('Crédit impossible côté serveur.');
  }

  log(`Credited user ${userId} +${credits} (product ${productId}).`);
  return res.json({ ok: true, credits });
};
