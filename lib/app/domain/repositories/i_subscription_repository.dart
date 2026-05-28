import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/plan_entity.dart';
import '../entities/store_product_entity.dart';
import '../entities/store_purchase_event_entity.dart';
import '../entities/subscription_entity.dart';

abstract class ISubscriptionRepository {
  Stream<StorePurchaseEventEntity> get purchaseUpdates;

  Future<Either<Failure, SubscriptionEntity?>> getMySubscription();
  Future<Either<Failure, List<SubscriptionEntity>>> getSubscriptionHistory();
  Future<Either<Failure, List<PlanEntity>>> getAvailablePlans();
  Future<Either<Failure, SubscriptionEntity?>> changePlan(int planId);
  Future<Either<Failure, SubscriptionEntity?>> syncStorePurchase({
    required int planId,
    required String productId,
    required String purchaseToken,
    String? purchaseId,
  });
  Future<Either<Failure, SubscriptionEntity?>> cancelSubscription();
  Future<Either<Failure, SubscriptionEntity?>> renewSubscription({
    required bool autoRenew,
  });
  Future<Either<Failure, bool>> isStoreAvailable();
  Future<Either<Failure, List<StoreProductEntity>>> getStoreProducts(
    Set<String> productIds,
  );
  Future<Either<Failure, void>> buyProduct({
    required String productId,
    String? applicationUserName,
  });
  Future<Either<Failure, void>> restorePurchases({String? applicationUserName});
  Future<Either<Failure, void>> completePurchase(String productId);
  Future<Either<Failure, void>> syncStoredUser({
    SubscriptionEntity? activeSubscription,
    List<SubscriptionEntity>? subscriptions,
  });
}
