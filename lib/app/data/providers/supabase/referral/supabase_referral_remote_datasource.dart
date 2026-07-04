import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../datasources/referral_datasource.dart';
import '../../../models/referral_model.dart';
import '../shared/supabase_table_names.dart';
import '../shared/supabase_user_scope.dart';

class SupabaseReferralRemoteDataSource implements IReferralRemoteDataSource {
  SupabaseReferralRemoteDataSource({required this.client})
    : userScope = SupabaseUserScope(client: client);

  final SupabaseClient client;
  final SupabaseUserScope userScope;

  @override
  Future<ReferralSummaryModel> getSummary() async {
    final userId = await userScope.getCurrentUserId();
    final user = await userScope.getUserRowByEmail(
      userScope.currentAuthUser.email!,
    );
    final referrals = await _getReferralRows(userId);
    final withdrawals = await getWithdrawals();

    var pendingCents = 0;
    var approvedCents = 0;
    var paidCents = 0;

    for (final referral in referrals) {
      final amount = referral['rewardCents'] as int? ?? 0;
      switch (referral['status']?.toString()) {
        case 'approved':
          approvedCents += amount;
          break;
        case 'paid':
          paidCents += amount;
          break;
        case 'rejected':
          break;
        default:
          pendingCents += amount;
      }
    }

    for (final withdrawal in withdrawals) {
      if (withdrawal.status == 'paid') {
        paidCents += withdrawal.amountCents;
      }
      if (withdrawal.status == 'requested' ||
          withdrawal.status == 'processing' ||
          withdrawal.status == 'paid') {
        approvedCents -= withdrawal.amountCents;
      }
    }

    return ReferralSummaryModel(
      referralCode: user['referralCode']?.toString() ?? '',
      pendingCents: pendingCents,
      approvedCents: approvedCents < 0 ? 0 : approvedCents,
      paidCents: paidCents,
      totalReferrals: referrals.length,
    );
  }

  @override
  Future<List<ReferralModel>> getReferrals() async {
    final userId = await userScope.getCurrentUserId();
    final rows = await _getReferralRows(userId);
    return rows.map(ReferralModel.fromJson).toList();
  }

  @override
  Future<List<PixWithdrawalModel>> getWithdrawals() async {
    final userId = await userScope.getCurrentUserId();
    final rawRows = await client
        .from(SupabaseTableNames.pixWithdrawalRequests)
        .select()
        .eq('userId', userId)
        .order('createdAt', ascending: false);

    return (rawRows as List)
        .map(
          (row) => PixWithdrawalModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  @override
  Future<PixWithdrawalModel> requestPixWithdrawal({
    required int amountCents,
    required String cpf,
    required String pixKey,
  }) async {
    final userId = await userScope.getCurrentUserId();
    final summary = await getSummary();
    if (amountCents > summary.approvedCents) {
      throw PostgrestException(
        message: 'Saldo aprovado insuficiente para saque.',
      );
    }

    final inserted = await client
        .from(SupabaseTableNames.pixWithdrawalRequests)
        .insert({
          'userId': userId,
          'amountCents': amountCents,
          'cpf': cpf,
          'pixKey': pixKey,
          'status': 'requested',
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();

    return PixWithdrawalModel.fromJson(Map<String, dynamic>.from(inserted));
  }

  Future<List<Map<String, dynamic>>> _getReferralRows(int userId) async {
    final rawRows = await client
        .from(SupabaseTableNames.referrals)
        .select('*, referredUser:referredUserId(name,email)')
        .eq('referrerUserId', userId)
        .order('createdAt', ascending: false);

    return (rawRows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}
