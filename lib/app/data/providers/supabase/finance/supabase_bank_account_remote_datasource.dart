import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../domain/entities/bank_account_entity.dart';
import '../../../datasources/bank_account_datasource.dart';
import '../../../mappers/bank_account_codec.dart';
import '../../../models/bank_account_model.dart';
import '../shared/supabase_table_names.dart';
import '../shared/supabase_user_scope.dart';

class SupabaseBankAccountRemoteDataSource implements IBankAccountDataSource {
  SupabaseBankAccountRemoteDataSource({required this.client})
    : userScope = SupabaseUserScope(client: client);

  final SupabaseClient client;
  final SupabaseUserScope userScope;

  @override
  Future<List<BankAccountModel>> getBankAccounts() async {
    final userId = await userScope.getCurrentUserId();
    final rawAccounts = await client
        .from(SupabaseTableNames.bankAccounts)
        .select()
        .eq('userId', userId)
        .order('createdAt');
    final rawTransactions = await client
        .from(SupabaseTableNames.transactions)
        .select('bankAccountId,type,status,amountCents')
        .eq('userId', userId);

    final balanceDeltaByAccount = <int, int>{};
    for (final transaction in rawTransactions as List) {
      final row = Map<String, dynamic>.from(transaction as Map);
      final accountId = row['bankAccountId'] as int?;
      if (accountId == null) {
        continue;
      }

      if (!isClearedBankAccountTransaction(row)) {
        continue;
      }

      final amount = row['amountCents'] as int? ?? 0;
      final type = row['type']?.toString().toUpperCase() ?? 'EXPENSE';
      final signal = type == 'INCOME' ? 1 : -1;
      balanceDeltaByAccount.update(
        accountId,
        (current) => current + (amount * signal),
        ifAbsent: () => amount * signal,
      );
    }

    return (rawAccounts as List).map((account) {
      final row = Map<String, dynamic>.from(account as Map);
      final accountId = row['id'] as int;
      final initialBalance = row['initialBalanceCents'] as int? ?? 0;

      return BankAccountModel.fromJson({
        ...row,
        'currentBalanceCents':
            initialBalance + (balanceDeltaByAccount[accountId] ?? 0),
      });
    }).toList();
  }

  @override
  Future<BankAccountModel> createBankAccount({
    required String name,
    required String bankName,
    required String color,
    required AccountType accountType,
    required int initialBalanceCents,
  }) async {
    final userId = await userScope.getCurrentUserId();
    final now = DateTime.now().toUtc().toIso8601String();
    final inserted = await client
        .from(SupabaseTableNames.bankAccounts)
        .insert({
          'userId': userId,
          'name': name,
          'bankName': bankName,
          'color': color,
          'accountType': AccountTypeCodec.encode(accountType),
          'initialBalanceCents': initialBalanceCents,
          'currentBalanceCents': initialBalanceCents,
          'isActive': true,
          'updatedAt': now,
        })
        .select()
        .single();

    return BankAccountModel.fromJson(Map<String, dynamic>.from(inserted));
  }

  @override
  Future<BankAccountModel> updateBankAccount({
    required int id,
    required String name,
    required String bankName,
    required String color,
    required AccountType accountType,
    required int initialBalanceCents,
    bool? isActive,
  }) async {
    final current = await client
        .from(SupabaseTableNames.bankAccounts)
        .select()
        .eq('id', id)
        .single();
    final currentRow = Map<String, dynamic>.from(current);
    final previousInitialBalance =
        currentRow['initialBalanceCents'] as int? ?? 0;
    final previousCurrentBalance =
        currentRow['currentBalanceCents'] as int? ?? 0;
    final delta = previousCurrentBalance - previousInitialBalance;
    final payload = <String, dynamic>{
      'name': name,
      'bankName': bankName,
      'color': color,
      'accountType': AccountTypeCodec.encode(accountType),
      'initialBalanceCents': initialBalanceCents,
      'currentBalanceCents': initialBalanceCents + delta,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    if (isActive != null) {
      payload['isActive'] = isActive;
    }

    final updated = await client
        .from(SupabaseTableNames.bankAccounts)
        .update(payload)
        .eq('id', id)
        .select()
        .single();

    return BankAccountModel.fromJson(Map<String, dynamic>.from(updated));
  }

  @override
  Future<void> deactivateBankAccount(int id) async {
    await client
        .from(SupabaseTableNames.bankAccounts)
        .update({
          'isActive': false,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  @override
  Future<void> reactivateBankAccount(int id) async {
    await client
        .from(SupabaseTableNames.bankAccounts)
        .update({
          'isActive': true,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }
}

bool isClearedBankAccountTransaction(Map<String, dynamic> row) {
  return row['status']?.toString().toUpperCase() == 'CLEARED';
}
