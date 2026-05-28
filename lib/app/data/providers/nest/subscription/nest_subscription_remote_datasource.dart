import 'package:dio/dio.dart';

import '../../../datasources/subscription_datasource.dart';
import '../../../models/plan_model.dart';
import '../../../models/subscription_model.dart';

class NestSubscriptionRemoteDataSource
    implements ISubscriptionRemoteDataSource {
  NestSubscriptionRemoteDataSource({required this.dio});

  final Dio dio;

  @override
  Future<SubscriptionModel?> getMySubscription() async {
    final response = await dio.get('/subscriptions/me');
    return _extractActiveSubscription(response.data);
  }

  @override
  Future<List<SubscriptionModel>> getSubscriptionHistory() async {
    final response = await dio.get('/subscriptions/me/history');
    final data = response.data;
    final rawList = data is List
        ? data
        : data is Map
        ? (data['subscriptions'] ?? data['history'] ?? data['data'] ?? [])
        : [];

    if (rawList is! List) {
      return [];
    }

    return rawList
        .whereType<Map>()
        .map(
          (item) => SubscriptionModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  @override
  Future<List<PlanModel>> getAvailablePlans() async {
    final response = await dio.get('/admin/plans');
    final data = response.data;
    final rawList = data is List
        ? data
        : data is Map
        ? (data['plans'] ?? data['data'] ?? [])
        : [];

    if (rawList is! List) {
      return [];
    }

    return rawList
        .whereType<Map>()
        .map((item) => PlanModel.fromJson(Map<String, dynamic>.from(item)))
        .where((plan) => plan.isActive)
        .toList();
  }

  @override
  Future<SubscriptionModel?> changePlan(int planId) async {
    final response = await dio.post(
      '/subscriptions/me/change-plan',
      data: {'planId': planId},
    );
    return _extractActiveSubscription(response.data);
  }

  @override
  Future<SubscriptionModel?> syncStorePurchase({
    required int planId,
    required String productId,
    required String purchaseToken,
    String? purchaseId,
  }) async {
    final response = await dio.post(
      '/subscriptions/me/store-purchase',
      data: {
        'planId': planId,
        'productId': productId,
        'purchaseToken': purchaseToken,
        'purchaseId': purchaseId,
      },
    );
    return _extractActiveSubscription(response.data);
  }

  @override
  Future<SubscriptionModel?> cancelSubscription() async {
    final response = await dio.post('/subscriptions/me/cancel');
    return _extractActiveSubscription(response.data);
  }

  @override
  Future<SubscriptionModel?> renewSubscription({
    required bool autoRenew,
  }) async {
    final response = await dio.post(
      '/subscriptions/me/renew',
      data: {'autoRenew': autoRenew},
    );
    return _extractActiveSubscription(response.data);
  }

  SubscriptionModel? _extractActiveSubscription(dynamic data) {
    if (data is Map) {
      if (data['activeSubscription'] is Map) {
        return SubscriptionModel.fromJson(
          Map<String, dynamic>.from(data['activeSubscription'] as Map),
        );
      }
      if (data['subscription'] is Map) {
        return SubscriptionModel.fromJson(
          Map<String, dynamic>.from(data['subscription'] as Map),
        );
      }
      if (data['data'] is Map) {
        return _extractActiveSubscription(data['data']);
      }
      if (data['id'] != null && data['status'] != null) {
        return SubscriptionModel.fromJson(Map<String, dynamic>.from(data));
      }
    }

    return null;
  }
}
