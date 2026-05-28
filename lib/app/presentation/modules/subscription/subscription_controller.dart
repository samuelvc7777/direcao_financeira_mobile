import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/feedback/app_snackbar.dart';
import '../../../core/subscription/play_store_subscription_contract.dart';
import '../../../domain/entities/plan_entity.dart';
import '../../../domain/entities/store_product_entity.dart';
import '../../../domain/entities/store_purchase_event_entity.dart';
import '../../../domain/entities/subscription_entity.dart';
import '../../../domain/usecases/subscription_use_cases.dart';

class SubscriptionController extends GetxController {
  SubscriptionController({
    required this.getMySubscriptionUseCase,
    required this.getSubscriptionHistoryUseCase,
    required this.getAvailablePlansUseCase,
    required this.changePlanUseCase,
    required this.syncStorePurchaseUseCase,
    required this.cancelSubscriptionUseCase,
    required this.renewSubscriptionUseCase,
    required this.syncStoredUserSubscriptionUseCase,
    required this.isStoreAvailableUseCase,
    required this.getStoreProductsUseCase,
    required this.buyStoreProductUseCase,
    required this.restorePurchasesUseCase,
    required this.completePurchaseUseCase,
    required this.watchStorePurchaseUpdatesUseCase,
  });

  final GetMySubscriptionUseCase getMySubscriptionUseCase;
  final GetSubscriptionHistoryUseCase getSubscriptionHistoryUseCase;
  final GetAvailablePlansUseCase getAvailablePlansUseCase;
  final ChangePlanUseCase changePlanUseCase;
  final SyncStorePurchaseUseCase syncStorePurchaseUseCase;
  final CancelSubscriptionUseCase cancelSubscriptionUseCase;
  final RenewSubscriptionUseCase renewSubscriptionUseCase;
  final SyncStoredUserSubscriptionUseCase syncStoredUserSubscriptionUseCase;
  final IsStoreAvailableUseCase isStoreAvailableUseCase;
  final GetStoreProductsUseCase getStoreProductsUseCase;
  final BuyStoreProductUseCase buyStoreProductUseCase;
  final RestorePurchasesUseCase restorePurchasesUseCase;
  final CompletePurchaseUseCase completePurchaseUseCase;
  final WatchStorePurchaseUpdatesUseCase watchStorePurchaseUpdatesUseCase;

  final isLoading = true.obs;
  final isActionLoading = false.obs;
  final hasPlanCatalog = true.obs;
  final errorMessage = RxnString();
  final activeSubscription = Rxn<SubscriptionEntity>();
  final history = <SubscriptionEntity>[].obs;
  final plans = <PlanEntity>[].obs;
  final selectedPlanId = RxnInt();

  final isStoreAvailable = false.obs;
  final isStoreCatalogLoading = false.obs;
  final isPurchaseLoading = false.obs;
  final isRestoringPurchases = false.obs;
  final isStoreSyncingPurchase = false.obs;
  final storeErrorMessage = RxnString();
  final pendingPurchaseProductId = RxnString();
  final storeProductsById = <String, StoreProductEntity>{}.obs;

  StreamSubscription<StorePurchaseEventEntity>? _purchaseSubscription;
  bool _didCompleteInitialBootstrap = false;
  Future<void>? _activeLoadFuture;
  DateTime? _manualRestoreSyncAllowedUntil;

  final currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  final dateFormatter = DateFormat('dd/MM/yyyy', 'pt_BR');

  bool get usesPlayStoreBilling => isStoreAvailable.value;

  @override
  void onInit() {
    super.onInit();
    debugPrint(
      '[SubscriptionController] onInit -> abrindo tela de assinatura.',
    );
    _listenToPurchaseUpdates();
    unawaited(loadData());
  }

  @override
  void onClose() {
    _purchaseSubscription?.cancel();
    _activeLoadFuture = null;
    _didCompleteInitialBootstrap = false;
    super.onClose();
  }

  Future<void> loadData() async {
    await _loadSubscriptionData(isBootstrap: true, source: 'loadData');
  }

  Future<void> reloadData() async {
    await _loadSubscriptionData(isBootstrap: false, source: 'reloadData');
  }

  Future<void> _loadSubscriptionData({
    required bool isBootstrap,
    required String source,
  }) async {
    if (_activeLoadFuture != null) {
      await _activeLoadFuture;
      return;
    }

    if (isBootstrap && _didCompleteInitialBootstrap) {
      debugPrint(
        '[SubscriptionController] $source -> bootstrap inicial ja concluido, ignorando nova carga automatica.',
      );
      return;
    }

    final loadFuture = _performSubscriptionLoad(
      isBootstrap: isBootstrap,
      source: source,
    );
    _activeLoadFuture = loadFuture;
    try {
      await loadFuture;
      if (isBootstrap) {
        _didCompleteInitialBootstrap = true;
      }
    } finally {
      if (identical(_activeLoadFuture, loadFuture)) {
        _activeLoadFuture = null;
      }
    }
  }

  Future<void> _performSubscriptionLoad({
    required bool isBootstrap,
    required String source,
  }) async {
    debugPrint('[SubscriptionController] $source -> iniciando carregamento.');
    isLoading.value = true;
    errorMessage.value = null;
    storeErrorMessage.value = null;

    final activeSubscriptionFuture = getMySubscriptionUseCase();
    final historyFuture = getSubscriptionHistoryUseCase();
    final plansFuture = getAvailablePlansUseCase();

    final activeResult = await activeSubscriptionFuture;
    final historyResult = await historyFuture;
    final plansResult = await plansFuture;

    activeResult.fold(
      (failure) => errorMessage.value = failure.message,
      (subscription) => activeSubscription.value = subscription,
    );

    historyResult.fold((failure) {
      if (errorMessage.value == null) {
        errorMessage.value = failure.message;
      }
    }, (subscriptionHistory) => history.assignAll(subscriptionHistory));

    plansResult.fold((_) => hasPlanCatalog.value = false, (availablePlans) {
      plans.assignAll(availablePlans);
      hasPlanCatalog.value = availablePlans.isNotEmpty;
    });

    _syncSelectedPlan();
    await _loadStoreCatalog();
    _syncSelectedPlan();
    await syncStoredUserSubscriptionUseCase(
      activeSubscription: activeSubscription.value,
      subscriptions: history,
    );
    _logSubscriptionState(source);
    _logActiveSubscriptionState(source);

    isLoading.value = false;
  }

  Future<void> changePlan() async {
    final planId = selectedPlanId.value;
    if (planId == null) {
      _showFeedback(
        title: 'Plano necessario',
        message: 'Selecione um plano antes de continuar.',
        isError: true,
      );
      return;
    }

    await _runAction(
      action: () => changePlanUseCase(planId),
      successMessage: 'Plano alterado com sucesso.',
    );
  }

  Future<void> purchaseSelectedPlan() async {
    final plan = selectedPlan;
    if (plan == null) {
      debugPrint(
        '[SubscriptionController] purchaseSelectedPlan bloqueado -> nenhum plano selecionado.',
      );
      _showFeedback(
        title: 'Plano necessario',
        message: 'Selecione um plano antes de continuar.',
        isError: true,
      );
      return;
    }

    if (!usesPlayStoreBilling) {
      _showFeedback(
        title: 'Play Store indisponivel',
        message:
            'Nao foi possivel abrir a assinatura pela Play Store neste aparelho.',
        isError: true,
      );
      return;
    }

    final product = storeProductForPlan(plan);
    if (product == null) {
      debugPrint(
        '[SubscriptionController] purchaseSelectedPlan bloqueado -> '
        'plano=${plan.id} code=${plan.code} sem produto correspondente. '
        'storeProducts=${storeProductsById.keys.toList()}',
      );
      _showFeedback(
        title: 'Produto indisponivel',
        message:
            'Este plano ainda nao foi encontrado na Play Store. Verifique se o productId publicado e igual ao code do plano.',
        isError: true,
      );
      return;
    }

    isPurchaseLoading.value = true;
    pendingPurchaseProductId.value = product.productId;

    final result = await buyStoreProductUseCase(
      productId: product.productId,
      applicationUserName: activeSubscription.value?.id.toString(),
    );

    result.fold(
      (failure) {
        pendingPurchaseProductId.value = null;
        _showFeedback(title: 'Erro', message: failure.message, isError: true);
      },
      (_) => _showFeedback(
        title: 'Play Store',
        message: 'Confirme a compra para concluir a assinatura.',
      ),
    );

    isPurchaseLoading.value = false;
  }

  Future<void> restorePurchases({bool showFeedback = true}) async {
    isRestoringPurchases.value = true;
    if (showFeedback) {
      _manualRestoreSyncAllowedUntil = DateTime.now().add(
        const Duration(seconds: 45),
      );
    }

    final result = await restorePurchasesUseCase();
    result.fold(
      (failure) {
        if (showFeedback) {
          _showFeedback(title: 'Erro', message: failure.message, isError: true);
        }
      },
      (_) {
        if (showFeedback) {
          _showFeedback(
            title: 'Play Store',
            message:
                'Buscando compras anteriores para restaurar sua assinatura.',
          );
        }
      },
    );

    isRestoringPurchases.value = false;
  }

  Future<void> cancelSubscription() async {
    await _runAction(
      action: cancelSubscriptionUseCase.call,
      successMessage: 'Assinatura cancelada com sucesso.',
    );
  }

  Future<void> renewSubscription({bool autoRenew = true}) async {
    await _runAction(
      action: () => renewSubscriptionUseCase(autoRenew: autoRenew),
      successMessage: autoRenew
          ? 'Renovacao automatica ativada com sucesso.'
          : 'Assinatura atualizada com sucesso.',
    );
  }

  PlanEntity? get selectedPlan {
    final planId = selectedPlanId.value;
    if (planId == null) {
      return null;
    }

    for (final plan in plans) {
      if (plan.id == planId) {
        return plan;
      }
    }

    return null;
  }

  StoreProductEntity? storeProductForPlan(PlanEntity plan) {
    return storeProductsById[plan.code];
  }

  String planPriceLabel(PlanEntity plan) {
    final product = storeProductForPlan(plan);
    return product?.recurringPriceLabel ??
        product?.priceLabel ??
        formatPrice(plan.priceCents);
  }

  String planBillingLabel(PlanEntity plan) {
    final price = planPriceLabel(plan);
    final trialLabel = storeProductForPlan(plan)?.trialLabel;
    if (trialLabel == null) {
      return '$price / ${plan.durationDays} dias';
    }

    return 'Depois $price / ${plan.durationDays} dias';
  }

  String? planTrialLabel(PlanEntity plan) {
    return storeProductForPlan(plan)?.trialLabel;
  }

  bool hasStoreProductForPlan(PlanEntity plan) {
    return storeProductForPlan(plan) != null;
  }

  bool get canPurchaseSelectedPlan {
    final plan = selectedPlan;
    if (plan == null) {
      return false;
    }

    if (!usesPlayStoreBilling) {
      return false;
    }

    if (isStoreCatalogLoading.value || storeErrorMessage.value != null) {
      return false;
    }

    return hasStoreProductForPlan(plan);
  }

  String ctaLabelForSelectedPlan() {
    final plan = selectedPlan;
    if (plan == null) {
      return 'SELECIONE UM PLANO';
    }

    if (!usesPlayStoreBilling) {
      return 'ASSINAR NA PLAY STORE';
    }

    if (isCurrentPlan(plan)) {
      return 'RENOVAR NA PLAY STORE';
    }

    return storeProductForPlan(plan)?.hasFreeTrial == true
        ? 'COMECAR TESTE GRATIS'
        : 'ASSINAR NA PLAY STORE';
  }

  String formatPrice(int priceCents) =>
      currencyFormatter.format(priceCents / 100);

  String formatDate(DateTime? date) {
    if (date == null) {
      return 'Nao informado';
    }
    return dateFormatter.format(date.toLocal());
  }

  String formatStatus(String status) {
    const labels = {
      'ACTIVE': 'Ativa',
      'CANCELED': 'Cancelada',
      'EXPIRED': 'Expirada',
      'PENDING': 'Pendente',
      'TRIAL': 'Teste',
    };

    return labels[status.toUpperCase()] ?? status;
  }

  Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFF03A696);
      case 'CANCELED':
        return const Color(0xFFBF4124);
      case 'EXPIRED':
        return const Color(0xFFF2B366);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  bool isCurrentPlan(PlanEntity plan) {
    return activeSubscription.value?.plan?.id == plan.id;
  }

  bool get isActiveSubscriptionGooglePlayManaged {
    return activeSubscription.value?.isGooglePlayManaged ?? false;
  }

  Future<void> _loadStoreCatalog() async {
    storeErrorMessage.value = null;
    storeProductsById.clear();

    final storeAvailabilityResult = await isStoreAvailableUseCase();
    final storeAvailable = storeAvailabilityResult.fold(
      (_) => false,
      (value) => value,
    );
    isStoreAvailable.value = storeAvailable;
    debugPrint(
      '[SubscriptionController] _loadStoreCatalog -> '
      'storeAvailable=$storeAvailable',
    );

    if (!storeAvailable) {
      debugPrint(
        '[SubscriptionController] _loadStoreCatalog -> loja indisponivel, sem catalogo.',
      );
      return;
    }

    final supportedPlans = plans
        .map((plan) => plan.code.trim())
        .where(isSupportedAndroidSubscriptionCode)
        .toSet();
    final unsupportedCodes = plans
        .map((plan) => plan.code.trim())
        .where((code) => !isSupportedAndroidSubscriptionCode(code))
        .toSet();

    if (unsupportedCodes.isNotEmpty) {
      debugPrint(
        '[SubscriptionController] _loadStoreCatalog -> '
        'codigo(s) nao suportado(s)=$unsupportedCodes',
      );
    }

    if (supportedPlans.isEmpty) {
      storeErrorMessage.value =
          'Nenhum plano compativel com a Play Store foi encontrado no backend.';
      debugPrint(
        '[SubscriptionController] _loadStoreCatalog -> nenhum plano suportado encontrado.',
      );
      return;
    }

    final productIds = supportedPlans
        .where((code) => code.trim().isNotEmpty)
        .toSet();
    if (productIds.isEmpty) {
      storeErrorMessage.value =
          'Nenhum plano possui code configurado para a Play Store.';
      debugPrint(
        '[SubscriptionController] _loadStoreCatalog -> nenhum plano com code configurado.',
      );
      return;
    }

    isStoreCatalogLoading.value = true;
    final productsResult = await getStoreProductsUseCase(productIds);
    productsResult.fold(
      (failure) {
        storeErrorMessage.value = failure.message;
        debugPrint(
          '[SubscriptionController] _loadStoreCatalog -> erro ao carregar produtos: '
          '${failure.message}',
        );
      },
      (products) {
        storeProductsById.assignAll(_selectPreferredStoreProducts(products));
        debugPrint(
          '[SubscriptionController] _loadStoreCatalog -> produtos retornados=${storeProductsById.keys.toList()}',
        );

        if (products.isEmpty) {
          storeErrorMessage.value =
              'A Google Play nao retornou nenhum produto para os planos ativos.';
          debugPrint(
            '[SubscriptionController] _loadStoreCatalog -> catalogo vazio.',
          );
          return;
        }

        if (!storeProductsById.keys.any(
          supportedAndroidSubscriptionProductIds.contains,
        )) {
          storeErrorMessage.value =
              'Nenhum plano oficial da Google Play foi encontrado para os planos ativos.';
          debugPrint(
            '[SubscriptionController] _loadStoreCatalog -> produto oficial nao encontrado.',
          );
        }
      },
    );
    isStoreCatalogLoading.value = false;
  }

  Map<String, StoreProductEntity> _selectPreferredStoreProducts(
    List<StoreProductEntity> products,
  ) {
    final preferredById = <String, StoreProductEntity>{};
    for (final product in products) {
      final current = preferredById[product.productId];
      if (current == null || _isBetterStoreProduct(product, current)) {
        preferredById[product.productId] = product;
      }
    }
    return preferredById;
  }

  bool _isBetterStoreProduct(
    StoreProductEntity candidate,
    StoreProductEntity current,
  ) {
    final candidateTrialDays = candidate.trialDays ?? 0;
    final currentTrialDays = current.trialDays ?? 0;
    if (candidateTrialDays != currentTrialDays) {
      return candidateTrialDays > currentTrialDays;
    }

    return candidate.rawPrice < current.rawPrice;
  }

  void _listenToPurchaseUpdates() {
    _purchaseSubscription = watchStorePurchaseUpdatesUseCase().listen((
      event,
    ) async {
      switch (event.status) {
        case StorePurchaseStatus.pending:
          pendingPurchaseProductId.value = event.productId;
          _showFeedback(
            title: 'Compra em andamento',
            message: 'Aguardando confirmacao da Play Store.',
          );
          break;
        case StorePurchaseStatus.purchased:
          if (pendingPurchaseProductId.value != event.productId) {
            debugPrint(
              '[SubscriptionController] compra ignorada -> '
              'productId=${event.productId} sem compra iniciada nesta sessao.',
            );
            return;
          }
          await _syncPurchaseWithSubscription(event);
          break;
        case StorePurchaseStatus.restored:
          if (!_canSyncRestoredPurchase()) {
            debugPrint(
              '[SubscriptionController] restore ignorado -> '
              'productId=${event.productId} sem restauracao manual recente.',
            );
            return;
          }
          await _syncPurchaseWithSubscription(event);
          break;
        case StorePurchaseStatus.canceled:
          pendingPurchaseProductId.value = null;
          _showFeedback(
            title: 'Compra cancelada',
            message: 'A compra foi cancelada antes da confirmacao.',
            isError: true,
          );
          break;
        case StorePurchaseStatus.error:
          pendingPurchaseProductId.value = null;
          _showFeedback(
            title: 'Erro na compra',
            message: event.errorMessage ?? 'Falha ao processar a compra.',
            isError: true,
          );
          break;
      }
    });
  }

  Future<void> _syncPurchaseWithSubscription(
    StorePurchaseEventEntity event,
  ) async {
    if (event.productId.isEmpty || isStoreSyncingPurchase.value) {
      return;
    }

    final plan = _findPlanByProductId(event.productId);
    if (plan == null) {
      _showFeedback(
        title: 'Produto desconhecido',
        message:
            'A compra retornou da Play Store, mas nenhum plano com esse code foi encontrado no app.',
        isError: true,
      );
      return;
    }

    isStoreSyncingPurchase.value = true;
    pendingPurchaseProductId.value = event.productId;

    final purchaseToken = event.verificationData.trim();
    if (purchaseToken.isEmpty) {
      isStoreSyncingPurchase.value = false;
      pendingPurchaseProductId.value = null;
      _showFeedback(
        title: 'Compra recebida',
        message:
            'A Play Store confirmou a compra, mas nao retornou o token necessario para sincronizar com o Supabase.',
        isError: true,
      );
      return;
    }

    final result = await syncStorePurchaseUseCase(
      planId: plan.id,
      productId: event.productId,
      purchaseToken: purchaseToken,
      purchaseId: event.purchaseId,
    );

    await result.fold(
      (failure) async {
        _showFeedback(
          title: 'Compra recebida',
          message:
              '${failure.message} A compra voltou da Play Store, mas a sincronizacao com a API nao foi concluida.',
          isError: true,
        );
      },
      (_) async {
        await completePurchaseUseCase(event.productId);
        await reloadData();
        _showFeedback(
          title: 'Sucesso',
          message: event.status == StorePurchaseStatus.restored
              ? 'Compra restaurada e assinatura sincronizada com sucesso.'
              : 'Compra confirmada e assinatura atualizada com sucesso.',
        );
      },
    );

    isStoreSyncingPurchase.value = false;
    pendingPurchaseProductId.value = null;
  }

  bool _canSyncRestoredPurchase() {
    final allowedUntil = _manualRestoreSyncAllowedUntil;
    return allowedUntil != null && DateTime.now().isBefore(allowedUntil);
  }

  PlanEntity? _findPlanByProductId(String productId) {
    for (final plan in plans) {
      if (plan.code == productId) {
        return plan;
      }
    }

    return null;
  }

  Future<void> _runAction({
    required Future<dynamic> Function() action,
    required String successMessage,
  }) async {
    isActionLoading.value = true;

    final result = await action();
    result.fold(
      (failure) =>
          _showFeedback(title: 'Erro', message: failure.message, isError: true),
      (_) async {
        await reloadData();
        _showFeedback(title: 'Sucesso', message: successMessage);
      },
    );

    isActionLoading.value = false;
  }

  void _syncSelectedPlan() {
    final currentPlanId = activeSubscription.value?.plan?.id;
    final currentPlan = activeSubscription.value?.plan;
    if (currentPlan != null &&
        (!usesPlayStoreBilling ||
            isSupportedAndroidSubscriptionCode(currentPlan.code))) {
      selectedPlanId.value = currentPlanId;
      debugPrint(
        '[SubscriptionController] _syncSelectedPlan -> plano atual selecionado id=$currentPlanId',
      );
      return;
    }

    if (usesPlayStoreBilling) {
      for (final plan in plans) {
        if (isSupportedAndroidSubscriptionCode(plan.code)) {
          selectedPlanId.value = plan.id;
          debugPrint(
            '[SubscriptionController] _syncSelectedPlan -> selecionando plano suportado id=${plan.id} code=${plan.code}',
          );
          return;
        }
      }
    }

    if (plans.isNotEmpty) {
      selectedPlanId.value = plans.first.id;
      debugPrint(
        '[SubscriptionController] _syncSelectedPlan -> selecionando primeiro plano id=${plans.first.id}',
      );
    }
  }

  void _logSubscriptionState(String source) {
    final plan = selectedPlan;
    debugPrint(
      '[SubscriptionController] $source -> '
      'usesPlayStoreBilling=$usesPlayStoreBilling '
      'isStoreAvailable=${isStoreAvailable.value} '
      'isStoreCatalogLoading=${isStoreCatalogLoading.value} '
      'selectedPlanId=${selectedPlanId.value} '
      'selectedPlanCode=${plan?.code} '
      'selectedPlanIdDomain=${plan?.id} '
      'plans=${plans.map((item) => "${item.id}:${item.code}").toList()} '
      'storeProducts=${storeProductsById.keys.toList()} '
      'storeErrorMessage=${storeErrorMessage.value} '
      'canPurchaseSelectedPlan=$canPurchaseSelectedPlan',
    );
  }

  void _logActiveSubscriptionState(String source) {
    final subscription = activeSubscription.value;
    debugPrint(
      '[SubscriptionController] $source activeSubscription -> '
      'id=${subscription?.id} '
      'status=${subscription?.status} '
      'autoRenew=${subscription?.autoRenew} '
      'endDate=${subscription?.endDate?.toIso8601String()} '
      'updatedAt=${subscription?.updatedAt?.toIso8601String()} '
      'plan=${subscription?.plan?.id}:${subscription?.plan?.code}',
    );
  }

  void _showFeedback({
    required String title,
    required String message,
    bool isError = false,
  }) {
    AppSnackbar.show(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError
          ? const Color(0xFFBF4124).withValues(alpha: 0.12)
          : const Color(0xFF03A696).withValues(alpha: 0.12),
      margin: const EdgeInsets.all(16),
    );
  }
}
