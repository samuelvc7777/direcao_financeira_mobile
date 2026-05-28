import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/user_entity.dart';

abstract class UserCache {
  Future<void> saveUser(UserEntity user);
  UserEntity? getUser();
  Future<void> clearUser();
  Future<void> syncUserSubscription({
    SubscriptionEntity? activeSubscription,
    List<SubscriptionEntity>? subscriptions,
  });
}
