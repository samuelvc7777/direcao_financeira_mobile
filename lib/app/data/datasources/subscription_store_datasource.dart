import '../../domain/entities/store_product_entity.dart';
import '../../domain/entities/store_purchase_event_entity.dart';

abstract class ISubscriptionStoreDataSource {
  Stream<StorePurchaseEventEntity> get purchaseUpdates;

  Future<bool> isAvailable();
  Future<List<StoreProductEntity>> getProductsByIds(Set<String> productIds);
  Future<void> buyProduct({
    required String productId,
    String? applicationUserName,
  });
  Future<void> restorePurchases({String? applicationUserName});
  Future<void> completePurchase(String productId);
  Future<void> dispose();
}
