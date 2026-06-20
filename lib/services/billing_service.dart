import 'dart:async';
import 'dart:convert';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'appwrite_client.dart';
import 'analytics_service.dart';

/// Achats intégrés via Google Play Billing, pour les **crédits Tuteur**
/// (biens numériques — exigés par les règles du Play Store).
///
/// Chaque achat est **vérifié côté serveur** par la fonction Appwrite
/// `verify-purchase` (qui contrôle le reçu auprès de Google Play puis crédite le
/// compte). L'app ne crédite jamais elle-même : elle se fie au verdict serveur.
class BillingService {
  BillingService._();
  static final BillingService instance = BillingService._();

  /// Produits Play Console (ID → nombre de crédits accordés). À créer dans
  /// Play Console → Monetize → Products → In-app products (consommables).
  static const Map<String, int> creditProducts = {
    'ob_credits_5': 5,
    'ob_credits_15': 15,
    'ob_credits_40': 40,
  };

  static const _verifyFunctionId = 'verify-purchase';
  static const _packageName = 'cm.luvvix.onbuch';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  // Callbacks branchés par l'UI.
  void Function(int creditsAdded)? onCredited;
  void Function(String message)? onError;
  void Function()? onPending;

  /// Démarre l'écoute du flux d'achats (à appeler avant tout achat).
  void start() {
    _sub ??= _iap.purchaseStream.listen(
      _onPurchases,
      onError: (e) => onError?.call('$e'),
    );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  Future<bool> isAvailable() => _iap.isAvailable();

  /// Récupère les produits depuis Play (prix localisé), triés par crédits.
  Future<List<ProductDetails>> loadProducts() async {
    final resp = await _iap.queryProductDetails(creditProducts.keys.toSet());
    final list = resp.productDetails;
    list.sort((a, b) => (creditProducts[a.id] ?? 0).compareTo(creditProducts[b.id] ?? 0));
    return list;
  }

  Future<void> buy(ProductDetails product) async {
    // Crédits = consommables (rachetables).
    await _iap.buyConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          onPending?.call();
          break;
        case PurchaseStatus.canceled:
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
          break;
        case PurchaseStatus.error:
          onError?.call(p.error?.message ?? 'Achat impossible.');
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final ok = await _verify(p);
          // Consomme le produit côté store quoi qu'il arrive (sinon il reste
          // « possédé » et bloque un nouvel achat).
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
          if (ok) {
            AnalyticsService.logEvent('credits_purchased', {'product': p.productID, 'credits': creditProducts[p.productID] ?? 0});
            onCredited?.call(creditProducts[p.productID] ?? 0);
          } else {
            onError?.call('Paiement reçu mais vérification échouée. Réessaie ou contacte le support.');
          }
          break;
      }
    }
  }

  /// Vérifie le reçu côté serveur (fonction Appwrite) et crédite le compte.
  Future<bool> _verify(PurchaseDetails p) async {
    try {
      final exec = await AppwriteClient.functions.createExecution(
        functionId: _verifyFunctionId,
        body: jsonEncode({
          'productId': p.productID,
          'purchaseToken': p.verificationData.serverVerificationData,
          'packageName': _packageName,
        }),
      );
      if (exec.responseStatusCode != 200) return false;
      final body = jsonDecode(exec.responseBody) as Map<String, dynamic>;
      return body['ok'] == true;
    } catch (_) {
      return false;
    }
  }
}
