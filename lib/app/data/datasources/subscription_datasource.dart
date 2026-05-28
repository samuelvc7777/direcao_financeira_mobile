import '../../core/session/user_cache.dart';
import '../../domain/entities/subscription_entity.dart';
import '../models/plan_model.dart';
import '../models/subscription_model.dart';

abstract class ISubscriptionRemoteDataSource {
  Future<SubscriptionModel?> getMySubscription();
  Future<List<SubscriptionModel>> getSubscriptionHistory();
  Future<List<PlanModel>> getAvailablePlans();
  Future<SubscriptionModel?> changePlan(int planId);
  Future<SubscriptionModel?> syncStorePurchase({
    required int planId,
    required String productId,
    required String purchaseToken,
    String? purchaseId,
  });
  Future<SubscriptionModel?> cancelSubscription();
  Future<SubscriptionModel?> renewSubscription({required bool autoRenew});
}

abstract class ISubscriptionLocalDataSource {
  Future<void> syncStoredUser({
    SubscriptionEntity? activeSubscription,
    List<SubscriptionEntity>? subscriptions,
  });
}

class SubscriptionLocalDataSource implements ISubscriptionLocalDataSource {
  SubscriptionLocalDataSource({required this.userCache});

  final UserCache userCache;

  @override
  Future<void> syncStoredUser({
    SubscriptionEntity? activeSubscription,
    List<SubscriptionEntity>? subscriptions,
  }) async {
    await userCache.syncUserSubscription(
      activeSubscription: activeSubscription,
      subscriptions: subscriptions,
    );
  }
}
