import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../datasources/subscription_datasource.dart';
import '../../../models/plan_model.dart';
import '../../../models/subscription_model.dart';
import '../shared/supabase_table_names.dart';
import '../shared/supabase_user_scope.dart';

class SupabaseSubscriptionRemoteDataSource
    implements ISubscriptionRemoteDataSource {
  SupabaseSubscriptionRemoteDataSource({required this.client})
    : userScope = SupabaseUserScope(client: client);

  final SupabaseClient client;
  final SupabaseUserScope userScope;

  @override
  Future<SubscriptionModel?> getMySubscription() async {
    final userId = await userScope.getCurrentUserId();
    return userScope.getActiveSubscription(userId);
  }

  @override
  Future<List<SubscriptionModel>> getSubscriptionHistory() async {
    final userId = await userScope.getCurrentUserId();
    return userScope.getSubscriptionHistory(userId);
  }

  @override
  Future<List<PlanModel>> getAvailablePlans() async {
    debugPrint(
      '[SupabaseSubscriptionRemoteDataSource] getAvailablePlans -> consultando planos ativos.',
    );

    final rows = await client
        .from(SupabaseTableNames.plans)
        .select()
        .eq('isActive', true)
        .order('priceCents');

    final rawRows = rows as List;
    debugPrint(
      '[SupabaseSubscriptionRemoteDataSource] getAvailablePlans -> linhas brutas=${rawRows.length} dados=$rawRows',
    );

    final plans = rawRows
        .map((row) => PlanModel.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();

    debugPrint(
      '[SupabaseSubscriptionRemoteDataSource] getAvailablePlans -> planos mapeados=${plans.map((plan) => "${plan.id}:${plan.code}").toList()}',
    );

    return plans;
  }

  @override
  Future<SubscriptionModel?> changePlan(int planId) async {
    final userId = await userScope.getCurrentUserId();
    final now = DateTime.now().toUtc();
    final planRow = await client
        .from(SupabaseTableNames.plans)
        .select()
        .eq('id', planId)
        .single();
    final plan = PlanModel.fromJson(Map<String, dynamic>.from(planRow));

    final active = await userScope.getActiveSubscription(userId);
    if (active != null) {
      await client
          .from(SupabaseTableNames.subscriptions)
          .update({
            'status': 'CANCELED',
            'canceledAt': now.toIso8601String(),
            'autoRenew': false,
            'updatedAt': now.toIso8601String(),
          })
          .eq('id', active.id);
    }

    final inserted = await client
        .from(SupabaseTableNames.subscriptions)
        .insert({
          'userId': userId,
          'planId': plan.id,
          'status': 'ACTIVE',
          'startDate': now.toIso8601String(),
          'endDate': now
              .add(Duration(days: plan.durationDays))
              .toUtc()
              .toIso8601String(),
          'autoRenew': false,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        })
        .select()
        .single();

    return SubscriptionModel.fromJson({
      ...Map<String, dynamic>.from(inserted),
      'plan': plan.toJson(),
    });
  }

  @override
  Future<SubscriptionModel?> syncStorePurchase({
    required int planId,
    required String productId,
    required String purchaseToken,
    String? purchaseId,
  }) async {
    final normalizedToken = purchaseToken.trim();
    if (normalizedToken.isEmpty) {
      throw const AuthException(
        'Compra recebida sem token de verificacao da Play Store.',
      );
    }

    final userId = await userScope.getCurrentUserId();
    final now = DateTime.now().toUtc();
    final planRow = await client
        .from(SupabaseTableNames.plans)
        .select()
        .eq('id', planId)
        .single();
    final plan = PlanModel.fromJson(Map<String, dynamic>.from(planRow));
    final fallbackEndDate = now.add(Duration(days: plan.durationDays)).toUtc();

    final existingRow = await client
        .from(SupabaseTableNames.subscriptions)
        .select()
        .eq('googlePlayPurchaseToken', normalizedToken)
        .limit(1)
        .maybeSingle();

    if (existingRow != null) {
      return _refreshExistingGooglePlaySubscription(
        existingRow: Map<String, dynamic>.from(existingRow),
        userId: userId,
        plan: plan,
        productId: productId,
        purchaseId: purchaseId,
        fallbackEndDate: fallbackEndDate,
        now: now,
      );
    }

    final active = await userScope.getActiveSubscription(userId);
    if (active != null) {
      await client
          .from(SupabaseTableNames.subscriptions)
          .update({
            'status': 'CANCELED',
            'canceledAt': now.toIso8601String(),
            'autoRenew': false,
            'updatedAt': now.toIso8601String(),
          })
          .eq('id', active.id);
    }

    Map<String, dynamic> inserted;
    try {
      inserted = Map<String, dynamic>.from(
        await client
            .from(SupabaseTableNames.subscriptions)
            .insert({
              'userId': userId,
              'planId': plan.id,
              'status': 'ACTIVE',
              'startDate': now.toIso8601String(),
              'endDate': fallbackEndDate.toIso8601String(),
              'autoRenew': true,
              'googlePlayProductId': productId,
              'googlePlayPurchaseToken': normalizedToken,
              'googlePlayOrderId': purchaseId,
              'googlePlayLinkedAt': now.toIso8601String(),
              'googlePlayExpiresAt': fallbackEndDate.toIso8601String(),
              'createdAt': now.toIso8601String(),
              'updatedAt': now.toIso8601String(),
            })
            .select()
            .single(),
      );
    } on PostgrestException catch (error) {
      final isDuplicatePurchaseToken =
          error.code == '23505' &&
          (error.message.contains('googlePlayPurchaseToken') ||
              error.details.toString().contains('googlePlayPurchaseToken'));
      if (!isDuplicatePurchaseToken) {
        rethrow;
      }

      final duplicatedRow = await client
          .from(SupabaseTableNames.subscriptions)
          .select()
          .eq('googlePlayPurchaseToken', normalizedToken)
          .limit(1)
          .single();

      return _refreshExistingGooglePlaySubscription(
        existingRow: Map<String, dynamic>.from(duplicatedRow),
        userId: userId,
        plan: plan,
        productId: productId,
        purchaseId: purchaseId,
        fallbackEndDate: fallbackEndDate,
        now: now,
      );
    }

    return SubscriptionModel.fromJson({...inserted, 'plan': plan.toJson()});
  }

  Future<SubscriptionModel> _refreshExistingGooglePlaySubscription({
    required Map<String, dynamic> existingRow,
    required Object userId,
    required PlanModel plan,
    required String productId,
    required String? purchaseId,
    required DateTime fallbackEndDate,
    required DateTime now,
  }) async {
    final existing = SubscriptionModel.fromJson({
      ...existingRow,
      'plan': plan.toJson(),
    });
    final preservedEndDate =
        existing.endDate != null && existing.endDate!.isAfter(now)
        ? existing.endDate!
        : fallbackEndDate;
    final existingGooglePlayExpiresAt = existingRow['googlePlayExpiresAt']
        ?.toString();
    final existingGooglePlayOrderId = existingRow['googlePlayOrderId']
        ?.toString();

    final updated = await client
        .from(SupabaseTableNames.subscriptions)
        .update({
          'userId': userId,
          'planId': plan.id,
          'status': 'ACTIVE',
          'endDate': preservedEndDate.toIso8601String(),
          'canceledAt': null,
          'autoRenew': existing.autoRenew,
          'googlePlayProductId': productId,
          'googlePlayOrderId': purchaseId ?? existingGooglePlayOrderId,
          'googlePlayLinkedAt': now.toIso8601String(),
          'googlePlayExpiresAt':
              existingGooglePlayExpiresAt ?? preservedEndDate.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        })
        .eq('id', existing.id)
        .select()
        .single();

    return SubscriptionModel.fromJson({
      ...Map<String, dynamic>.from(updated),
      'plan': plan.toJson(),
    });
  }

  @override
  Future<SubscriptionModel?> cancelSubscription() async {
    final active = await getMySubscription();
    if (active == null) {
      return null;
    }

    final now = DateTime.now().toUtc();

    final updated = await client
        .from(SupabaseTableNames.subscriptions)
        .update({
          'status': 'CANCELED',
          'canceledAt': now.toIso8601String(),
          'autoRenew': false,
          'updatedAt': now.toIso8601String(),
        })
        .eq('id', active.id)
        .select()
        .single();

    return SubscriptionModel.fromJson({
      ...Map<String, dynamic>.from(updated),
      if (active.plan != null)
        'plan': {
          'id': active.plan!.id,
          'code': active.plan!.code,
          'name': active.plan!.name,
          'description': active.plan!.description,
          'priceCents': active.plan!.priceCents,
          'durationDays': active.plan!.durationDays,
          'color': active.plan!.color,
          'isActive': active.plan!.isActive,
          'createdAt': active.plan!.createdAt?.toIso8601String(),
          'updatedAt': active.plan!.updatedAt?.toIso8601String(),
        },
    });
  }

  @override
  Future<SubscriptionModel?> renewSubscription({
    required bool autoRenew,
  }) async {
    final active = await getMySubscription();
    if (active == null) {
      return null;
    }

    final now = DateTime.now().toUtc();

    final updated = await client
        .from(SupabaseTableNames.subscriptions)
        .update({'autoRenew': autoRenew, 'updatedAt': now.toIso8601String()})
        .eq('id', active.id)
        .select()
        .single();

    return SubscriptionModel.fromJson({
      ...Map<String, dynamic>.from(updated),
      if (active.plan != null)
        'plan': {
          'id': active.plan!.id,
          'code': active.plan!.code,
          'name': active.plan!.name,
          'description': active.plan!.description,
          'priceCents': active.plan!.priceCents,
          'durationDays': active.plan!.durationDays,
          'color': active.plan!.color,
          'isActive': active.plan!.isActive,
          'createdAt': active.plan!.createdAt?.toIso8601String(),
          'updatedAt': active.plan!.updatedAt?.toIso8601String(),
        },
    });
  }
}
