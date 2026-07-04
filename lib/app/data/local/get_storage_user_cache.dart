import 'package:get_storage/get_storage.dart';

import '../../core/errors/exceptions.dart';
import '../../core/session/user_cache.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../models/subscription_model.dart';
import '../models/user_model.dart';

class GetStorageUserCache implements UserCache {
  GetStorageUserCache({required this.storage});

  final GetStorage storage;
  static const _userKey = 'user';

  @override
  Future<void> saveUser(UserEntity user) async {
    try {
      final model = user is UserModel
          ? user
          : UserModel(
              id: user.id,
              email: user.email,
              name: user.name,
              role: user.role,
              isActive: user.isActive,
              createdAt: user.createdAt,
              updatedAt: user.updatedAt,
              profilePhotoBase64: user.profilePhotoBase64,
              activeSubscription: user.activeSubscription,
              subscriptions: user.subscriptions,
            );

      await storage.write(_userKey, model.toJson());
    } catch (_) {
      throw const LocalDataSourceException('Erro ao salvar usuario.');
    }
  }

  @override
  UserEntity? getUser() {
    try {
      final rawUser = storage.read(_userKey);
      if (rawUser is! Map) {
        return null;
      }

      return UserModel.fromJson(Map<String, dynamic>.from(rawUser));
    } catch (_) {
      throw const LocalDataSourceException('Erro ao ler usuario.');
    }
  }

  @override
  Future<void> clearUser() async {
    try {
      await storage.remove(_userKey);
    } catch (_) {
      throw const LocalDataSourceException('Erro ao limpar usuario.');
    }
  }

  @override
  Future<void> syncUserSubscription({
    SubscriptionEntity? activeSubscription,
    List<SubscriptionEntity>? subscriptions,
  }) async {
    try {
      final rawUser = storage.read(_userKey);
      if (rawUser is! Map) {
        return;
      }

      final updatedUser = Map<String, dynamic>.from(rawUser);
      if (activeSubscription != null ||
          updatedUser.containsKey('activeSubscription')) {
        updatedUser['activeSubscription'] = activeSubscription == null
            ? null
            : _subscriptionToJson(activeSubscription);
      }

      if (subscriptions != null) {
        updatedUser['subscriptions'] = subscriptions
            .map(_subscriptionToJson)
            .toList();
      }

      await storage.write(_userKey, updatedUser);
    } catch (_) {
      throw const LocalDataSourceException(
        'Erro ao sincronizar assinatura do usuario.',
      );
    }
  }

  Map<String, dynamic> _subscriptionToJson(SubscriptionEntity subscription) {
    if (subscription is SubscriptionModel) {
      return subscription.toJson();
    }

    return SubscriptionModel(
      id: subscription.id,
      status: subscription.status,
      startDate: subscription.startDate,
      endDate: subscription.endDate,
      canceledAt: subscription.canceledAt,
      autoRenew: subscription.autoRenew,
      createdAt: subscription.createdAt,
      updatedAt: subscription.updatedAt,
      plan: subscription.plan,
    ).toJson();
  }
}
