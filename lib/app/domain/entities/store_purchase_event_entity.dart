enum StorePurchaseStatus { pending, purchased, restored, canceled, error }

class StorePurchaseEventEntity {
  final String productId;
  final String? purchaseId;
  final StorePurchaseStatus status;
  final String? errorMessage;
  final bool pendingCompletePurchase;
  final String verificationData;
  final String verificationSource;

  const StorePurchaseEventEntity({
    required this.productId,
    required this.purchaseId,
    required this.status,
    required this.pendingCompletePurchase,
    required this.verificationData,
    required this.verificationSource,
    this.errorMessage,
  });
}
