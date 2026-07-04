import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/session/user_cache.dart';
import '../../core/subscription/play_store_subscription_contract.dart';
import '../../domain/entities/help_video_entity.dart';
import '../../domain/entities/plan_entity.dart';
import '../../domain/repositories/i_help_repository.dart';
import '../../domain/services/premium_access_policy.dart';
import '../../domain/usecases/help_use_cases.dart';
import '../../domain/usecases/subscription_use_cases.dart';
import '../modules/help/widgets/help_video_fullscreen_view.dart';
import '../modules/subscription/subscription_binding.dart';
import '../modules/subscription/subscription_controller.dart';
import '../../routes/app_pages.dart';
import 'premium_access_banner.dart';

class PremiumAccessGuard {
  PremiumAccessGuard({
    PremiumAccessPolicy? policy,
    UserCache? userCache,
    GetMySubscriptionUseCase? getMySubscriptionUseCase,
    SyncStoredUserSubscriptionUseCase? syncStoredUserSubscriptionUseCase,
  }) : _policy = policy ?? Get.find<PremiumAccessPolicy>(),
       _userCache = userCache ?? Get.find<UserCache>(),
       _getMySubscriptionUseCase = getMySubscriptionUseCase,
       _syncStoredUserSubscriptionUseCase = syncStoredUserSubscriptionUseCase;

  final PremiumAccessPolicy _policy;
  final UserCache _userCache;
  final GetMySubscriptionUseCase? _getMySubscriptionUseCase;
  final SyncStoredUserSubscriptionUseCase? _syncStoredUserSubscriptionUseCase;

  static bool _isShowingBanner = false;

  static void resetForTesting() {
    _isShowingBanner = false;
  }

  Future<void> run(FutureOr<void> Function() action) async {
    if (_isCachedSubscriptionAllowed()) {
      await action();
      return;
    }

    final refreshed = await _refreshSubscriptionBeforeBlock();
    if (refreshed && _isCachedSubscriptionAllowed()) {
      await action();
      return;
    }

    await showBlockedBanner();
  }

  bool _isCachedSubscriptionAllowed() {
    final subscription = _userCache.getUser()?.activeSubscription;
    return _policy.evaluate(subscription).isAllowed;
  }

  Future<bool> _refreshSubscriptionBeforeBlock() async {
    final refreshUseCases = _tryFindRefreshUseCases();
    if (refreshUseCases == null) {
      return false;
    }

    final currentSubscriptions = _userCache.getUser()?.subscriptions;
    final liveResult = await refreshUseCases.getMySubscriptionUseCase();
    return liveResult.fold<Future<bool>>((_) async => false, (
      liveSubscription,
    ) async {
      final syncResult = await refreshUseCases
          .syncStoredUserSubscriptionUseCase(
            activeSubscription: liveSubscription,
            subscriptions: currentSubscriptions,
          );
      return syncResult.fold((_) => false, (_) => true);
    });
  }

  Future<void> showBlockedBanner() async {
    if (_isShowingBanner || (Get.isBottomSheetOpen ?? false)) {
      return;
    }

    _isShowingBanner = true;
    try {
      final subscriptionController = _tryFindSubscriptionController();
      final demoVideo = await _loadDemoVideo();
      await Get.bottomSheet<void>(
        PremiumAccessBanner(
          onStartTrial: subscriptionController == null
              ? null
              : (plan) async {
                  _selectPlan(subscriptionController, plan);
                  await subscriptionController.purchaseSelectedPlan();
                },
          onViewSubscription: () {
            if (Get.isBottomSheetOpen ?? false) {
              Get.back<void>();
            }
            Get.toNamed(AppRoutes.subscription);
          },
          onRestoreSubscription: subscriptionController == null
              ? null
              : () => subscriptionController.restorePurchases(),
          demoVideo: demoVideo,
          onWatchDemoVideo: demoVideo == null
              ? null
              : () => _openDemoVideo(demoVideo),
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.42),
      );
    } finally {
      _isShowingBanner = false;
    }
  }

  Future<HelpVideoEntity?> _loadDemoVideo() async {
    try {
      final useCase = Get.isRegistered<LoadFeaturedHelpVideoUseCase>()
          ? Get.find<LoadFeaturedHelpVideoUseCase>()
          : LoadFeaturedHelpVideoUseCase(Get.find<IHelpRepository>());
      final result = await useCase();
      return result.fold((_) => null, (video) => video);
    } catch (error) {
      debugPrint(
        '[PremiumAccessGuard] video demonstrativo indisponivel: $error',
      );
      return null;
    }
  }

  void _openDemoVideo(HelpVideoEntity video) {
    if (Get.isBottomSheetOpen ?? false) {
      Get.back<void>();
    }

    Get.to<void>(
      () => HelpVideoFullscreenView(video: video),
      fullscreenDialog: true,
    );
  }

  SubscriptionController? _tryFindSubscriptionController() {
    try {
      SubscriptionBinding().dependencies();
      return Get.find<SubscriptionController>();
    } catch (error) {
      debugPrint(
        '[PremiumAccessGuard] controller de assinatura indisponivel no banner: $error',
      );
      return null;
    }
  }

  _SubscriptionRefreshUseCases? _tryFindRefreshUseCases() {
    if (_getMySubscriptionUseCase != null &&
        _syncStoredUserSubscriptionUseCase != null) {
      return _SubscriptionRefreshUseCases(
        getMySubscriptionUseCase: _getMySubscriptionUseCase,
        syncStoredUserSubscriptionUseCase: _syncStoredUserSubscriptionUseCase,
      );
    }

    try {
      SubscriptionBinding().dependencies();
      return _SubscriptionRefreshUseCases(
        getMySubscriptionUseCase: Get.find<GetMySubscriptionUseCase>(),
        syncStoredUserSubscriptionUseCase:
            Get.find<SyncStoredUserSubscriptionUseCase>(),
      );
    } catch (error) {
      debugPrint(
        '[PremiumAccessGuard] sincronizacao de assinatura indisponivel: $error',
      );
      return null;
    }
  }

  void _selectPlan(SubscriptionController controller, PremiumPlan plan) {
    final productId = switch (plan) {
      PremiumPlan.monthly => playStoreMonthlySubscriptionProductId,
      PremiumPlan.yearly => playStoreAnnualSubscriptionProductId,
    };
    final selectedPlan = _findPlanByCode(controller.plans, productId);
    if (selectedPlan != null) {
      controller.selectedPlanId.value = selectedPlan.id;
    }
  }

  PlanEntity? _findPlanByCode(Iterable<PlanEntity> plans, String code) {
    for (final plan in plans) {
      if (plan.code.trim() == code) {
        return plan;
      }
    }
    return null;
  }
}

class _SubscriptionRefreshUseCases {
  const _SubscriptionRefreshUseCases({
    required this.getMySubscriptionUseCase,
    required this.syncStoredUserSubscriptionUseCase,
  });

  final GetMySubscriptionUseCase getMySubscriptionUseCase;
  final SyncStoredUserSubscriptionUseCase syncStoredUserSubscriptionUseCase;
}
