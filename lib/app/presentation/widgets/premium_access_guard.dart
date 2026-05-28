import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/session/user_cache.dart';
import '../../domain/services/premium_access_policy.dart';
import '../../routes/app_pages.dart';
import 'premium_access_banner.dart';

class PremiumAccessGuard {
  PremiumAccessGuard({PremiumAccessPolicy? policy, UserCache? userCache})
    : _policy = policy ?? Get.find<PremiumAccessPolicy>(),
      _userCache = userCache ?? Get.find<UserCache>();

  final PremiumAccessPolicy _policy;
  final UserCache _userCache;

  static bool _isShowingBanner = false;

  static void resetForTesting() {
    _isShowingBanner = false;
  }

  Future<void> run(FutureOr<void> Function() action) async {
    final subscription = _userCache.getUser()?.activeSubscription;
    final decision = _policy.evaluate(subscription);

    if (decision.isAllowed) {
      await action();
      return;
    }

    await showBlockedBanner();
  }

  Future<void> showBlockedBanner() async {
    if (_isShowingBanner || (Get.isBottomSheetOpen ?? false)) {
      return;
    }

    _isShowingBanner = true;
    try {
      await Get.bottomSheet<void>(
        PremiumAccessBanner(
          onViewSubscription: () {
            if (Get.isBottomSheetOpen ?? false) {
              Get.back<void>();
            }
            Get.toNamed(AppRoutes.subscription);
          },
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.42),
      );
    } finally {
      _isShowingBanner = false;
    }
  }
}
