import '../../domain/entities/user_entity.dart';
import 'subscription_model.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    required super.isActive,
    super.createdAt,
    super.updatedAt,
    super.profilePhotoBase64,
    super.activeSubscription,
    super.subscriptions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final activeSubscription = json['activeSubscription'];
    final subscriptions = json['subscriptions'] as List<dynamic>? ?? const [];

    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: json['role'],
      isActive: json['isActive'] ?? true,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      profilePhotoBase64: json['profilePhotoBase64']?.toString(),
      activeSubscription: activeSubscription is Map
          ? SubscriptionModel.fromJson(
              Map<String, dynamic>.from(activeSubscription),
            )
          : null,
      subscriptions: subscriptions
          .whereType<Map>()
          .map(
            (subscription) => SubscriptionModel.fromJson(
              Map<String, dynamic>.from(subscription),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'profilePhotoBase64': profilePhotoBase64,
      'activeSubscription': activeSubscription == null
          ? null
          : activeSubscription is SubscriptionModel
          ? (activeSubscription as SubscriptionModel).toJson()
          : SubscriptionModel(
              id: activeSubscription!.id,
              status: activeSubscription!.status,
              startDate: activeSubscription!.startDate,
              endDate: activeSubscription!.endDate,
              canceledAt: activeSubscription!.canceledAt,
              autoRenew: activeSubscription!.autoRenew,
              createdAt: activeSubscription!.createdAt,
              updatedAt: activeSubscription!.updatedAt,
              googlePlayProductId: activeSubscription!.googlePlayProductId,
              googlePlayPurchaseToken:
                  activeSubscription!.googlePlayPurchaseToken,
              plan: activeSubscription!.plan,
            ).toJson(),
      'subscriptions': subscriptions
          .map(
            (subscription) => subscription is SubscriptionModel
                ? subscription.toJson()
                : SubscriptionModel(
                    id: subscription.id,
                    status: subscription.status,
                    startDate: subscription.startDate,
                    endDate: subscription.endDate,
                    canceledAt: subscription.canceledAt,
                    autoRenew: subscription.autoRenew,
                    createdAt: subscription.createdAt,
                    updatedAt: subscription.updatedAt,
                    googlePlayProductId: subscription.googlePlayProductId,
                    googlePlayPurchaseToken:
                        subscription.googlePlayPurchaseToken,
                    plan: subscription.plan,
                  ).toJson(),
          )
          .toList(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
