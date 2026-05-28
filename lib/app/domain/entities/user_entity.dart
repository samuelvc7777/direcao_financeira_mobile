import 'subscription_entity.dart';

class UserEntity {
  final int id;
  final String email;
  final String name;
  final String role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? profilePhotoBase64;
  final SubscriptionEntity? activeSubscription;
  final List<SubscriptionEntity> subscriptions;

  UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.profilePhotoBase64,
    this.activeSubscription,
    this.subscriptions = const [],
  });
}
