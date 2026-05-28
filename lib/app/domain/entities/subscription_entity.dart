import 'plan_entity.dart';

class SubscriptionEntity {
  final int id;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? canceledAt;
  final bool autoRenew;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? googlePlayProductId;
  final String? googlePlayPurchaseToken;
  final PlanEntity? plan;

  SubscriptionEntity({
    required this.id,
    required this.status,
    this.startDate,
    this.endDate,
    this.canceledAt,
    required this.autoRenew,
    this.createdAt,
    this.updatedAt,
    this.googlePlayProductId,
    this.googlePlayPurchaseToken,
    this.plan,
  });

  bool get isGooglePlayManaged {
    final productId = googlePlayProductId?.trim() ?? '';
    final purchaseToken = googlePlayPurchaseToken?.trim() ?? '';
    return productId.isNotEmpty || purchaseToken.isNotEmpty;
  }

  bool get grantsAccess {
    final normalizedStatus = status.toUpperCase();
    final allowsGraceAccess =
        normalizedStatus == 'ACTIVE' ||
        normalizedStatus == 'TRIAL' ||
        normalizedStatus == 'CANCELED';
    if (!allowsGraceAccess) {
      return false;
    }

    return endDate == null || endDate!.isAfter(DateTime.now());
  }
}
