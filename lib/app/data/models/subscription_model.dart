import '../../domain/entities/subscription_entity.dart';
import 'plan_model.dart';

class SubscriptionModel extends SubscriptionEntity {
  SubscriptionModel({
    required super.id,
    required super.status,
    super.startDate,
    super.endDate,
    super.canceledAt,
    required super.autoRenew,
    super.createdAt,
    super.updatedAt,
    super.googlePlayProductId,
    super.googlePlayPurchaseToken,
    super.plan,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'];

    return SubscriptionModel(
      id: json['id'],
      status: json['status'] ?? 'UNKNOWN',
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      canceledAt: _parseDate(json['canceledAt']),
      autoRenew: json['autoRenew'] ?? false,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      googlePlayProductId: json['googlePlayProductId']?.toString(),
      googlePlayPurchaseToken: json['googlePlayPurchaseToken']?.toString(),
      plan: plan is Map
          ? PlanModel.fromJson(Map<String, dynamic>.from(plan))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'canceledAt': canceledAt?.toIso8601String(),
      'autoRenew': autoRenew,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'googlePlayProductId': googlePlayProductId,
      'googlePlayPurchaseToken': googlePlayPurchaseToken,
      'plan': plan == null
          ? null
          : plan is PlanModel
          ? (plan as PlanModel).toJson()
          : PlanModel(
              id: plan!.id,
              code: plan!.code,
              name: plan!.name,
              description: plan!.description,
              priceCents: plan!.priceCents,
              durationDays: plan!.durationDays,
              color: plan!.color,
              isActive: plan!.isActive,
              createdAt: plan!.createdAt,
              updatedAt: plan!.updatedAt,
            ).toJson(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
