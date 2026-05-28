import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/plan_entity.dart';
import '../entities/store_product_entity.dart';
import '../entities/store_purchase_event_entity.dart';
import '../entities/subscription_entity.dart';
import '../repositories/i_subscription_repository.dart';

class GetMySubscriptionUseCase {
  GetMySubscriptionUseCase(this._repository);

  final ISubscriptionRepository _repository;

  Future<Either<Failure, SubscriptionEntity?>> call() {
    return _repository.getMySubscription();
  }
}

class GetSubscriptionHistoryUseCase {
  GetSubscriptionHistoryUseCase(this._repository);

  final ISubscriptionRepository _repository;

  Future<Either<Failure, List<SubscriptionEntity>>> call() {
    return _repository.getSubscriptionHistory();
  }
}

class GetAvailablePlansUseCase {
  GetAvailablePlansUseCase(this._repository);

  final ISubscriptionRepository _repository;

  Future<Either<Failure, List<PlanEntity>>> call() {
    return _repository.getAvailablePlans();
  }
}

class ChangePlanUseCase {
  ChangePlanUseCase(this._repository);

  final ISubscriptionRepository _repository;

  Future<Either<Failure, SubscriptionEntity?>> call(int planId) {
    return _repository.changePlan(planId);
  }
}

class SyncStorePurchaseUseCase {
  SyncStorePurchaseUseCase(this._repository);

  final ISubscriptionRepository _repository;

  Future<Either<Failure, SubscriptionEntity?>> call({
    required int planId,
    required String productId,
    required String purchaseToken,
    String? purchaseId,
  }) {
    return _repository.syncStorePurchase(
      planId: planId,
      productId: productId,
      purchaseToken: purchaseToken,
      purchaseId: purchaseId,
    );
  }
}

class CancelSubscriptionUseCase {
  CancelSubscriptionUseCase(this._repository);

  final ISubscriptionRepository _repository;

  Future<Either<Failure, SubscriptionEntity?>> call() {
    return _repository.cancelSubscription();
  }
}

class RenewSubscriptionUseCase {
  RenewSubscriptionUseCase(this._repository);

  final ISubscriptionRepository _repository;

  Future<Either<Failure, SubscriptionEntity?>> call({required bool autoRenew}) {
    return _repository.renewSubscription(autoRenew: autoRenew);
  }
}

class SyncStoredUserSubscriptionUseCase {
  SyncStoredUserSubscriptionUseCase(this._repository);

  final ISubscriptionRepository _repository;

  Future<Either<Failure, void>> call({
    SubscriptionEntity? activeSubscription,
    List<SubscriptionEntity>? subscriptions,
  }) {
    return _repository.syncStoredUser(
      activeSubscription: activeSubscription,
      subscriptions: subscriptions,
    );
  }
}

class IsStoreAvailableUseCase {
  IsStoreAvailableUseCase(this._repository);

  final ISubscriptionRepository _repository;

  Future<Either<Failure, bool>> call() {
    return _repository.isStoreAvailable();
  }
}

class GetStoreProductsUseCase {
  GetStoreProductsUseCase(this._repository);

  final ISubscriptionRepository _repository;

  Future<Either<Failure, List<StoreProductEntity>>> call(
    Set<String> productIds,
  ) {
    return _repository.getStoreProducts(productIds);
  }
}

class BuyStoreProductUseCase {
  BuyStoreProductUseCase(this._repository);

  final ISubscriptionRepository _repository;

  Future<Either<Failure, void>> call({
    required String productId,
    String? applicationUserName,
  }) {
    return _repository.buyProduct(
      productId: productId,
      applicationUserName: applicationUserName,
    );
  }
}

class RestorePurchasesUseCase {
  RestorePurchasesUseCase(this._repository);

  final ISubscriptionRepository _repository;

  Future<Either<Failure, void>> call({String? applicationUserName}) {
    return _repository.restorePurchases(
      applicationUserName: applicationUserName,
    );
  }
}

class CompletePurchaseUseCase {
  CompletePurchaseUseCase(this._repository);

  final ISubscriptionRepository _repository;

  Future<Either<Failure, void>> call(String productId) {
    return _repository.completePurchase(productId);
  }
}

class WatchStorePurchaseUpdatesUseCase {
  WatchStorePurchaseUpdatesUseCase(this._repository);

  final ISubscriptionRepository _repository;

  Stream<StorePurchaseEventEntity> call() {
    return _repository.purchaseUpdates;
  }
}
