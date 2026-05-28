import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../domain/entities/transaction_entity.dart';
import '../../../../domain/entities/transaction_draft_entity.dart';
import '../../../datasources/transaction_datasource.dart';
import '../../../mappers/transaction_codecs.dart';
import '../../../models/transaction_model.dart';
import '../shared/supabase_table_names.dart';
import '../shared/supabase_user_scope.dart';

abstract class SupabaseTransactionUserScope {
  Future<int> getCurrentUserId();
}

abstract class SupabaseTransactionQueryGateway {
  Future<List<Map<String, dynamic>>> fetchTransactionsForMonth({
    required int userId,
    required DateTime startOfMonthUtc,
    required DateTime startOfNextMonthUtc,
  });

  Future<List<TransactionModel>> enrichTransactions(
    List<Map<String, dynamic>> rows,
  );
}

class SupabaseTransactionRemoteDataSource implements ITransactionDataSource {
  SupabaseTransactionRemoteDataSource({required SupabaseClient client})
    : this._(
        client: client,
        userScope: _SupabaseTransactionUserScopeAdapter(
          scope: SupabaseUserScope(client: client),
        ),
        queryGateway: _SupabaseTransactionQueryGateway(client: client),
      );

  SupabaseTransactionRemoteDataSource.forTest({
    required this.queryGateway,
    required this.userScope,
  }) : client = null;

  SupabaseTransactionRemoteDataSource._({
    required this.client,
    required this.userScope,
    required this.queryGateway,
  });

  final SupabaseClient? client;
  final SupabaseTransactionUserScope userScope;
  final SupabaseTransactionQueryGateway queryGateway;

  @override
  Future<List<TransactionModel>> getTransactions({
    required DateTime referenceMonth,
  }) async {
    final userId = await userScope.getCurrentUserId();
    final startOfMonthUtc = DateTime.utc(
      referenceMonth.year,
      referenceMonth.month,
    );
    final startOfNextMonthUtc = DateTime.utc(
      referenceMonth.year,
      referenceMonth.month + 1,
    );
    final rows = await queryGateway.fetchTransactionsForMonth(
      userId: userId,
      startOfMonthUtc: startOfMonthUtc,
      startOfNextMonthUtc: startOfNextMonthUtc,
    );

    return queryGateway.enrichTransactions(rows);
  }

  @override
  Future<TransactionModel> getTransaction(int id) async {
    final row = await client!
        .from(SupabaseTableNames.transactions)
        .select()
        .eq('id', id)
        .single();

    final enriched = await _enrichTransactions([
      Map<String, dynamic>.from(row),
    ]);
    return enriched.first;
  }

  @override
  Future<TransactionModel> createTransaction({
    required TransactionType type,
    TransactionStatus status = TransactionStatus.cleared,
    required AssetType assetType,
    required int amountCents,
    required int categoryId,
    required String description,
    required DateTime transactionDate,
    int? bankAccountId,
    int? creditCardId,
    int? installmentCount,
    int? recurrenceCount,
  }) async {
    final userId = await userScope.getCurrentUserId();
    final normalizedInstallmentCount =
        installmentCount != null && installmentCount > 1 ? installmentCount : 1;
    final normalizedRecurrenceCount =
        recurrenceCount != null && recurrenceCount > 1 ? recurrenceCount : 1;
    final seriesCount = normalizedRecurrenceCount > 1
        ? normalizedRecurrenceCount
        : normalizedInstallmentCount;
    final installmentGroupId = normalizedInstallmentCount > 1
        ? '${DateTime.now().microsecondsSinceEpoch}'
        : null;
    final recurrenceGroupId = normalizedRecurrenceCount > 1
        ? '${DateTime.now().microsecondsSinceEpoch}'
        : null;

    final payload = <Map<String, dynamic>>[];
    final now = DateTime.now().toUtc().toIso8601String();
    for (var index = 0; index < seriesCount; index++) {
      final entryStatus = normalizedRecurrenceCount > 1 && index > 0
          ? TransactionStatus.pending
          : status;
      final installmentDate = DateTime(
        transactionDate.year,
        transactionDate.month + index,
        transactionDate.day,
        transactionDate.hour,
        transactionDate.minute,
        transactionDate.second,
        transactionDate.millisecond,
        transactionDate.microsecond,
      );
      final entry = <String, dynamic>{
        'userId': userId,
        'type': TransactionTypeCodec.encode(type),
        'status': TransactionStatusCodec.encode(entryStatus),
        'assetType': AssetTypeCodec.encode(assetType),
        'amountCents': amountCents,
        'categoryId': categoryId,
        'description': description,
        'transactionDate': installmentDate.toUtc().toIso8601String(),
        'updatedAt': now,
      };
      if (bankAccountId != null) {
        entry['bankAccountId'] = bankAccountId;
      }
      if (creditCardId != null) {
        entry['creditCardId'] = creditCardId;
      }
      if (installmentGroupId != null) {
        entry['installmentGroupId'] = installmentGroupId;
        entry['installmentNumber'] = index + 1;
        entry['installmentCount'] = normalizedInstallmentCount;
      }
      if (recurrenceGroupId != null) {
        entry['recurrenceGroupId'] = recurrenceGroupId;
        entry['recurrenceNumber'] = index + 1;
        entry['recurrenceCount'] = normalizedRecurrenceCount;
      }
      payload.add(entry);
    }

    final inserted = await client!
        .from(SupabaseTableNames.transactions)
        .insert(payload)
        .select();

    final enriched = await _enrichTransactions(_toRowList(inserted));
    return enriched.first;
  }

  @override
  Future<List<TransactionModel>> createImportedTransactions({
    required List<TransactionDraftEntity> transactions,
  }) async {
    final created = <TransactionModel>[];
    for (final draft in transactions) {
      created.add(
        await createTransaction(
          type: draft.type,
          status: TransactionStatus.cleared,
          assetType: draft.assetType,
          amountCents: draft.amountCents,
          categoryId: draft.categoryId,
          description: draft.description,
          transactionDate: draft.transactionDate,
          bankAccountId: draft.bankAccountId,
          creditCardId: draft.creditCardId,
          installmentCount: draft.installmentCount,
          recurrenceCount: draft.recurrenceCount,
        ),
      );
    }
    return created;
  }

  @override
  Future<void> createInvoicePayment({
    required int bankAccountId,
    required int creditCardId,
    required int amountCents,
    required int expenseCategoryId,
    required int incomeCategoryId,
    required String description,
    required DateTime transactionDate,
  }) async {
    final userId = await userScope.getCurrentUserId();
    final now = DateTime.now().toUtc().toIso8601String();
    final paymentDate = transactionDate.toUtc().toIso8601String();

    await client!.from(SupabaseTableNames.transactions).insert([
      {
        'userId': userId,
        'type': TransactionTypeCodec.encode(TransactionType.expense),
        'status': TransactionStatusCodec.encode(TransactionStatus.cleared),
        'assetType': AssetTypeCodec.encode(AssetType.bankAccount),
        'amountCents': amountCents,
        'categoryId': expenseCategoryId,
        'description': description,
        'transactionDate': paymentDate,
        'bankAccountId': bankAccountId,
        'updatedAt': now,
      },
      {
        'userId': userId,
        'type': TransactionTypeCodec.encode(TransactionType.income),
        'status': TransactionStatusCodec.encode(TransactionStatus.cleared),
        'assetType': AssetTypeCodec.encode(AssetType.creditCard),
        'amountCents': amountCents,
        'categoryId': incomeCategoryId,
        'description': description,
        'transactionDate': paymentDate,
        'creditCardId': creditCardId,
        'updatedAt': now,
      },
    ]);
  }

  @override
  Future<TransactionModel> updateTransaction(
    int id, {
    TransactionStatus? status,
    int? categoryId,
    String? description,
    int? amountCents,
    DateTime? transactionDate,
    TransactionMutationScope? scope,
  }) async {
    final baseRow = await _getTransactionRow(id);
    final rowsToUpdate = await _resolveRowsForScope(baseRow, scope);

    if (scope == TransactionMutationScope.all &&
        _seriesGroupId(baseRow) != null &&
        transactionDate != null) {
      for (final row in rowsToUpdate) {
        final seriesNumber = _seriesNumber(row);
        final recalculatedDate = DateTime(
          transactionDate.year,
          transactionDate.month + ((seriesNumber ?? 1) - 1),
          transactionDate.day,
          transactionDate.hour,
          transactionDate.minute,
          transactionDate.second,
          transactionDate.millisecond,
          transactionDate.microsecond,
        );
        final recalculatedPayload = <String, dynamic>{
          'transactionDate': recalculatedDate.toUtc().toIso8601String(),
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        };
        if (categoryId != null) {
          recalculatedPayload['categoryId'] = categoryId;
        }
        if (status != null) {
          recalculatedPayload['status'] = TransactionStatusCodec.encode(status);
        }
        if (description != null) {
          recalculatedPayload['description'] = description;
        }
        if (amountCents != null) {
          recalculatedPayload['amountCents'] = amountCents;
        }

        await client!
            .from(SupabaseTableNames.transactions)
            .update(recalculatedPayload)
            .eq('id', row['id']);
      }
    } else {
      for (final row in rowsToUpdate) {
        final payload = <String, dynamic>{};
        if (categoryId != null) {
          payload['categoryId'] = categoryId;
        }
        if (status != null) {
          payload['status'] = TransactionStatusCodec.encode(status);
        }
        if (description != null) {
          payload['description'] = description;
        }
        if (amountCents != null) {
          payload['amountCents'] = amountCents;
        }
        if (transactionDate != null) {
          payload['transactionDate'] = transactionDate
              .toUtc()
              .toIso8601String();
        }
        payload['updatedAt'] = DateTime.now().toUtc().toIso8601String();

        await client!
            .from(SupabaseTableNames.transactions)
            .update(payload)
            .eq('id', row['id']);
      }
    }

    return getTransaction(id);
  }

  @override
  Future<void> deleteTransaction(
    int id, {
    TransactionMutationScope? scope,
  }) async {
    final baseRow = await _getTransactionRow(id);
    final rowsToDelete = await _resolveRowsForScope(baseRow, scope);
    final ids = rowsToDelete.map((row) => row['id'] as int).toList();

    await client!
        .from(SupabaseTableNames.transactions)
        .delete()
        .inFilter('id', ids);
  }

  Future<Map<String, dynamic>> _getTransactionRow(int id) async {
    final row = await client!
        .from(SupabaseTableNames.transactions)
        .select()
        .eq('id', id)
        .single();

    return Map<String, dynamic>.from(row);
  }

  Future<List<Map<String, dynamic>>> _resolveRowsForScope(
    Map<String, dynamic> baseRow,
    TransactionMutationScope? scope,
  ) async {
    if (scope != TransactionMutationScope.all ||
        _seriesGroupId(baseRow) == null) {
      return [baseRow];
    }

    final groupRows = await client!
        .from(SupabaseTableNames.transactions)
        .select()
        .eq(_seriesGroupColumn(baseRow), _seriesGroupId(baseRow)!)
        .order(_seriesNumberColumn(baseRow));

    return _toRowList(groupRows);
  }

  Future<List<TransactionModel>> _enrichTransactions(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) {
      return const [];
    }

    final categoryIds = rows
        .map((row) => row['categoryId'] as int?)
        .whereType<int>()
        .toSet()
        .toList();
    final bankAccountIds = rows
        .map((row) => row['bankAccountId'] as int?)
        .whereType<int>()
        .toSet()
        .toList();
    final creditCardIds = rows
        .map((row) => row['creditCardId'] as int?)
        .whereType<int>()
        .toSet()
        .toList();

    final categoriesById = <int, Map<String, dynamic>>{};
    final bankAccountsById = <int, Map<String, dynamic>>{};
    final creditCardsById = <int, Map<String, dynamic>>{};

    if (categoryIds.isNotEmpty) {
      final rawCategories = await client!
          .from(SupabaseTableNames.categories)
          .select('id,name,color,icon')
          .inFilter('id', categoryIds);
      for (final category in rawCategories as List) {
        final row = Map<String, dynamic>.from(category as Map);
        categoriesById[row['id'] as int] = row;
      }
    }

    if (bankAccountIds.isNotEmpty) {
      final rawAccounts = await client!
          .from(SupabaseTableNames.bankAccounts)
          .select('id,name')
          .inFilter('id', bankAccountIds);
      for (final account in rawAccounts as List) {
        final row = Map<String, dynamic>.from(account as Map);
        bankAccountsById[row['id'] as int] = row;
      }
    }

    if (creditCardIds.isNotEmpty) {
      final rawCards = await client!
          .from(SupabaseTableNames.creditCards)
          .select('id,name')
          .inFilter('id', creditCardIds);
      for (final card in rawCards as List) {
        final row = Map<String, dynamic>.from(card as Map);
        creditCardsById[row['id'] as int] = row;
      }
    }

    return rows.map((row) {
      final normalized = Map<String, dynamic>.from(row);
      normalized['category'] = categoriesById[row['categoryId'] as int?];
      normalized['bankAccount'] =
          bankAccountsById[row['bankAccountId'] as int?];
      normalized['creditCard'] = creditCardsById[row['creditCardId'] as int?];
      return TransactionModel.fromJson(normalized);
    }).toList();
  }

  List<Map<String, dynamic>> _toRowList(dynamic data) {
    if (data is! List) {
      return const [];
    }

    return data.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  String? _seriesGroupId(Map<String, dynamic> row) {
    return row['installmentGroupId'] as String? ??
        row['recurrenceGroupId'] as String?;
  }

  String _seriesGroupColumn(Map<String, dynamic> row) {
    return row['installmentGroupId'] != null
        ? 'installmentGroupId'
        : 'recurrenceGroupId';
  }

  String _seriesNumberColumn(Map<String, dynamic> row) {
    return row['installmentGroupId'] != null
        ? 'installmentNumber'
        : 'recurrenceNumber';
  }

  int? _seriesNumber(Map<String, dynamic> row) {
    return row['installmentNumber'] as int? ?? row['recurrenceNumber'] as int?;
  }
}

class _SupabaseTransactionUserScopeAdapter
    implements SupabaseTransactionUserScope {
  _SupabaseTransactionUserScopeAdapter({required this.scope});

  final SupabaseUserScope scope;

  @override
  Future<int> getCurrentUserId() => scope.getCurrentUserId();
}

class _SupabaseTransactionQueryGateway
    implements SupabaseTransactionQueryGateway {
  _SupabaseTransactionQueryGateway({required this.client});

  final SupabaseClient client;

  @override
  Future<List<Map<String, dynamic>>> fetchTransactionsForMonth({
    required int userId,
    required DateTime startOfMonthUtc,
    required DateTime startOfNextMonthUtc,
  }) async {
    final rows = await client
        .from(SupabaseTableNames.transactions)
        .select()
        .eq('userId', userId)
        .gte('transactionDate', startOfMonthUtc.toIso8601String())
        .lt('transactionDate', startOfNextMonthUtc.toIso8601String())
        .order('transactionDate', ascending: false);

    return rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  @override
  Future<List<TransactionModel>> enrichTransactions(
    List<Map<String, dynamic>> rows,
  ) async {
    final datasource = SupabaseTransactionRemoteDataSource(client: client);
    return datasource._enrichTransactions(rows);
  }
}
