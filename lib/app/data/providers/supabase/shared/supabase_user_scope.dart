import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/plan_model.dart';
import '../../../models/subscription_model.dart';
import '../../../models/user_model.dart';
import 'supabase_table_names.dart';

class SupabaseUserScope {
  SupabaseUserScope({required this.client});

  final SupabaseClient client;

  User get currentAuthUser {
    final user = client.auth.currentUser;
    if (user == null || (user.email ?? '').trim().isEmpty) {
      throw const AuthException('Sessao do Supabase nao encontrada.');
    }

    return user;
  }

  Future<int> getCurrentUserId() async {
    final row = await getUserRowByEmail(currentAuthUser.email!);
    return row['id'] as int;
  }

  Future<Map<String, dynamic>> getUserRowByEmail(String email) async {
    final row = await client
        .from(SupabaseTableNames.users)
        .select()
        .eq('email', email)
        .maybeSingle();

    if (row == null) {
      throw const AuthException(
        'Usuario autenticado no Supabase, mas sem perfil cadastrado na tabela User.',
      );
    }

    return Map<String, dynamic>.from(row);
  }

  Future<UserModel> ensureUserProfileForAuthUser({
    required String email,
    required String name,
  }) async {
    final existing = await client
        .from(SupabaseTableNames.users)
        .select()
        .eq('email', email)
        .maybeSingle();

    if (existing != null) {
      return getUserModelByEmail(email);
    }

    final inserted = await client
        .from(SupabaseTableNames.users)
        .insert({
          'email': email,
          'name': name,
          'password': 'SUPABASE_AUTH',
          'role': 'USER',
          'isActive': true,
          'profilePhotoBase64': null,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();

    return _buildUserModel(Map<String, dynamic>.from(inserted));
  }

  Future<UserModel> updateCurrentUserProfilePhotoBase64({
    required String? profilePhotoBase64,
  }) async {
    final normalizedPhoto = profilePhotoBase64?.trim().isEmpty == true
        ? null
        : profilePhotoBase64;

    final row = await client
        .from(SupabaseTableNames.users)
        .update({
          'profilePhotoBase64': normalizedPhoto,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('email', currentAuthUser.email!)
        .select()
        .single();

    return _buildUserModel(Map<String, dynamic>.from(row));
  }

  Future<UserModel> getCurrentUserModel() async {
    return getUserModelByEmail(currentAuthUser.email!);
  }

  Future<UserModel> getUserModelByEmail(String email) async {
    final row = await getUserRowByEmail(email);
    return _buildUserModel(row);
  }

  Future<SubscriptionModel?> getActiveSubscription(int userId) async {
    final history = await getSubscriptionHistory(userId);
    for (final subscription in history) {
      if (subscription.grantsAccess) {
        return subscription;
      }
    }

    return null;
  }

  Future<List<SubscriptionModel>> getSubscriptionHistory(int userId) async {
    final rawRows = await client
        .from(SupabaseTableNames.subscriptions)
        .select()
        .eq('userId', userId)
        .order('updatedAt', ascending: false)
        .order('createdAt', ascending: false);

    final rows = (rawRows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();

    final planIds = rows
        .map((row) => row['planId'] as int?)
        .whereType<int>()
        .toSet()
        .toList();

    final plansById = <int, PlanModel>{};
    if (planIds.isNotEmpty) {
      final rawPlans = await client
          .from(SupabaseTableNames.plans)
          .select()
          .inFilter('id', planIds);
      for (final plan in rawPlans as List) {
        final planRow = Map<String, dynamic>.from(plan as Map);
        plansById[planRow['id'] as int] = PlanModel.fromJson(planRow);
      }
    }

    return rows.map((row) {
      final normalized = Map<String, dynamic>.from(row);
      normalized['plan'] = plansById[row['planId'] as int?];
      return SubscriptionModel.fromJson(normalized);
    }).toList();
  }

  UserModel _buildUserModel(Map<String, dynamic> row) {
    return UserModel.fromJson({
      ...row,
      'activeSubscription': null,
      'subscriptions': const [],
    });
  }
}
