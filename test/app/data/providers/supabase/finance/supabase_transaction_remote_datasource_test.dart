import 'package:direcao_financeira_mobile/app/data/models/transaction_model.dart';
import 'package:direcao_financeira_mobile/app/data/providers/supabase/finance/supabase_transaction_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

class _SpySupabaseTransactionQueryGateway
    implements SupabaseTransactionQueryGateway {
  DateTime? capturedStart;
  DateTime? capturedEndExclusive;

  @override
  Future<List<Map<String, dynamic>>> fetchTransactionsForMonth({
    required int userId,
    required DateTime startOfMonthUtc,
    required DateTime startOfNextMonthUtc,
  }) async {
    capturedStart = startOfMonthUtc;
    capturedEndExclusive = startOfNextMonthUtc;
    return [
      {
        'id': 1,
        'userId': userId,
        'type': 'expense',
        'status': 'cleared',
        'assetType': 'bank_account',
        'amountCents': 1250,
        'categoryId': 9,
        'description': 'Combustivel',
        'transactionDate': startOfMonthUtc.toIso8601String(),
        'createdAt': startOfMonthUtc.toIso8601String(),
        'updatedAt': startOfMonthUtc.toIso8601String(),
      },
    ];
  }

  @override
  Future<List<TransactionModel>> enrichTransactions(
    List<Map<String, dynamic>> rows,
  ) async {
    return rows.map(TransactionModel.fromJson).toList();
  }
}

class _FakeUserScope implements SupabaseTransactionUserScope {
  @override
  Future<int> getCurrentUserId() async => 123;
}

void main() {
  group('SupabaseTransactionRemoteDataSource', () {
    test('filtra a consulta pelo inicio e fim exclusivo do mes pedido', () async {
      final gateway = _SpySupabaseTransactionQueryGateway();
      final datasource = SupabaseTransactionRemoteDataSource.forTest(
        queryGateway: gateway,
        userScope: _FakeUserScope(),
      );

      final result = await datasource.getTransactions(
        referenceMonth: DateTime(2026, 3, 18, 14, 30),
      );

      expect(result, hasLength(1));
      expect(gateway.capturedStart, DateTime.utc(2026, 3, 1));
      expect(gateway.capturedEndExclusive, DateTime.utc(2026, 4, 1));
      expect(gateway.capturedStart!.isBefore(gateway.capturedEndExclusive!), isTrue);
    });
  });
}
