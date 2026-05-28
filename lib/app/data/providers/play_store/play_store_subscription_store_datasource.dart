import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';

import '../../../core/subscription/play_store_subscription_contract.dart';
import '../../datasources/subscription_store_datasource.dart';
import '../../../domain/entities/store_product_entity.dart';
import '../../../domain/entities/store_purchase_event_entity.dart';

class PlayStoreSubscriptionStoreDataSource
    implements ISubscriptionStoreDataSource {
  PlayStoreSubscriptionStoreDataSource({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance {
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object error, StackTrace stackTrace) {
        _purchaseUpdatesController.add(
          StorePurchaseEventEntity(
            productId: '',
            purchaseId: null,
            status: StorePurchaseStatus.error,
            errorMessage: error.toString(),
            pendingCompletePurchase: false,
            verificationData: '',
            verificationSource: '',
          ),
        );
      },
    );
  }

  final InAppPurchase _inAppPurchase;
  final StreamController<StorePurchaseEventEntity> _purchaseUpdatesController =
      StreamController<StorePurchaseEventEntity>.broadcast();
  final Map<String, ProductDetails> _productsById = {};
  final Map<String, PurchaseDetails> _pendingPurchasesByProductId = {};
  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;

  @override
  Stream<StorePurchaseEventEntity> get purchaseUpdates =>
      _purchaseUpdatesController.stream;

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    return _inAppPurchase.isAvailable();
  }

  @override
  Future<List<StoreProductEntity>> getProductsByIds(
    Set<String> productIds,
  ) async {
    if (productIds.isEmpty) {
      return const [];
    }

    final response = await _inAppPurchase.queryProductDetails(productIds);
    final products = _selectPreferredProductDetails(response.productDetails);
    for (final product in products) {
      _productsById[product.id] = product;
    }

    return products.map(_mapProduct).toList();
  }

  @override
  Future<void> buyProduct({
    required String productId,
    String? applicationUserName,
  }) async {
    final product = _productsById[productId];
    if (product == null) {
      throw StateError(
        'Produto $productId nao encontrado na Play Store. '
        'No Android, o plano mensal precisa usar o ID '
        '$playStoreMonthlySubscriptionProductId e bater exatamente com o plan.code.',
      );
    }

    final purchaseParam = _buildPurchaseParam(
      product: product,
      applicationUserName: applicationUserName,
    );

    final didStart = await _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );

    if (!didStart) {
      throw StateError('Nao foi possivel iniciar a compra na Play Store.');
    }
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) {
    return _inAppPurchase.restorePurchases(
      applicationUserName: applicationUserName,
    );
  }

  @override
  Future<void> completePurchase(String productId) async {
    final purchase = _pendingPurchasesByProductId[productId];
    if (purchase == null || !purchase.pendingCompletePurchase) {
      return;
    }

    await _inAppPurchase.completePurchase(purchase);
    _pendingPurchasesByProductId.remove(productId);
  }

  @override
  Future<void> dispose() async {
    await _purchaseSubscription.cancel();
    await _purchaseUpdatesController.close();
  }

  PurchaseParam _buildPurchaseParam({
    required ProductDetails product,
    String? applicationUserName,
  }) {
    if (defaultTargetPlatform == TargetPlatform.android &&
        product is GooglePlayProductDetails) {
      return GooglePlayPurchaseParam(
        productDetails: product,
        applicationUserName: applicationUserName,
        offerToken: product.offerToken,
      );
    }

    return PurchaseParam(
      productDetails: product,
      applicationUserName: applicationUserName,
    );
  }

  StoreProductEntity _mapProduct(ProductDetails product) {
    final subscriptionOffer = _subscriptionOfferFor(product);
    final freeTrialPhase = subscriptionOffer?.pricingPhases
        .where(_isFreeTrialPhase)
        .firstOrNull;
    final recurringPhase = subscriptionOffer?.pricingPhases
        .where((phase) => phase.priceAmountMicros > 0)
        .lastOrNull;
    final trialDays = freeTrialPhase == null
        ? null
        : _daysFromBillingPeriod(
            freeTrialPhase.billingPeriod,
            freeTrialPhase.billingCycleCount,
          );

    return StoreProductEntity(
      productId: product.id,
      title: product.title,
      description: product.description,
      priceLabel: product.price,
      recurringPriceLabel: recurringPhase?.formattedPrice,
      rawPrice: product.rawPrice,
      currencyCode: product.currencyCode,
      trialDays: trialDays,
      trialLabel: trialDays == null ? null : _formatTrialLabel(trialDays),
      offerToken: product is GooglePlayProductDetails
          ? product.offerToken
          : null,
      basePlanId: subscriptionOffer?.basePlanId,
      offerId: subscriptionOffer?.offerId,
    );
  }

  List<ProductDetails> _selectPreferredProductDetails(
    List<ProductDetails> products,
  ) {
    final preferredById = <String, ProductDetails>{};
    for (final product in products) {
      final current = preferredById[product.id];
      if (current == null || _isBetterOffer(product, current)) {
        preferredById[product.id] = product;
      }
    }
    return preferredById.values.toList();
  }

  bool _isBetterOffer(ProductDetails candidate, ProductDetails current) {
    final candidateTrialDays = _trialDaysFor(candidate);
    final currentTrialDays = _trialDaysFor(current);
    if (candidateTrialDays != currentTrialDays) {
      return candidateTrialDays > currentTrialDays;
    }

    return candidate.rawPrice < current.rawPrice;
  }

  int _trialDaysFor(ProductDetails product) {
    final offer = _subscriptionOfferFor(product);
    if (offer == null) {
      return 0;
    }

    var days = 0;
    for (final phase in offer.pricingPhases.where(_isFreeTrialPhase)) {
      final phaseDays = _daysFromBillingPeriod(
        phase.billingPeriod,
        phase.billingCycleCount,
      );
      if (phaseDays != null && phaseDays > days) {
        days = phaseDays;
      }
    }
    return days;
  }

  SubscriptionOfferDetailsWrapper? _subscriptionOfferFor(
    ProductDetails product,
  ) {
    if (product is! GooglePlayProductDetails ||
        product.subscriptionIndex == null ||
        product.productDetails.subscriptionOfferDetails == null) {
      return null;
    }

    final offers = product.productDetails.subscriptionOfferDetails!;
    final index = product.subscriptionIndex!;
    if (index < 0 || index >= offers.length) {
      return null;
    }

    return offers[index];
  }

  bool _isFreeTrialPhase(PricingPhaseWrapper phase) {
    return phase.priceAmountMicros == 0 &&
        _daysFromBillingPeriod(phase.billingPeriod, phase.billingCycleCount) !=
            null;
  }

  int? _daysFromBillingPeriod(String billingPeriod, int billingCycleCount) {
    final match = RegExp(
      r'^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)W)?(?:(\d+)D)?$',
    ).firstMatch(billingPeriod);
    if (match == null) {
      return null;
    }

    final years = int.tryParse(match.group(1) ?? '') ?? 0;
    final months = int.tryParse(match.group(2) ?? '') ?? 0;
    final weeks = int.tryParse(match.group(3) ?? '') ?? 0;
    final days = int.tryParse(match.group(4) ?? '') ?? 0;
    final totalDays = years * 365 + months * 30 + weeks * 7 + days;
    if (totalDays <= 0) {
      return null;
    }

    final cycles = billingCycleCount <= 0 ? 1 : billingCycleCount;
    return totalDays * cycles;
  }

  String _formatTrialLabel(int days) {
    return days == 1 ? '1 dia gratis' : '$days dias gratis';
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.pendingCompletePurchase) {
        _pendingPurchasesByProductId[purchase.productID] = purchase;
      }

      _purchaseUpdatesController.add(
        StorePurchaseEventEntity(
          productId: purchase.productID,
          purchaseId: purchase.purchaseID,
          status: _mapPurchaseStatus(purchase.status),
          errorMessage: purchase.error?.message,
          pendingCompletePurchase: purchase.pendingCompletePurchase,
          verificationData: purchase.verificationData.serverVerificationData,
          verificationSource: purchase.verificationData.source,
        ),
      );
    }
  }

  StorePurchaseStatus _mapPurchaseStatus(PurchaseStatus status) {
    switch (status) {
      case PurchaseStatus.pending:
        return StorePurchaseStatus.pending;
      case PurchaseStatus.purchased:
        return StorePurchaseStatus.purchased;
      case PurchaseStatus.restored:
        return StorePurchaseStatus.restored;
      case PurchaseStatus.canceled:
        return StorePurchaseStatus.canceled;
      case PurchaseStatus.error:
        return StorePurchaseStatus.error;
    }
  }
}
