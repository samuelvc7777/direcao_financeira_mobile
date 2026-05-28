import 'package:dio/dio.dart';

import '../../../../domain/entities/transaction_entity.dart';
import '../../../../domain/entities/transaction_draft_entity.dart';
import '../../../datasources/transaction_datasource.dart';
import '../../../mappers/transaction_codecs.dart';
import '../../../models/transaction_model.dart';

class NestTransactionRemoteDataSource implements ITransactionDataSource {
  NestTransactionRemoteDataSource({required this.dio});

  final Dio dio;

  @override
  Future<List<TransactionModel>> getTransactions({
    required DateTime referenceMonth,
  }) async {
    final startOfMonth = DateTime(referenceMonth.year, referenceMonth.month);
    final startOfNextMonth = DateTime(
      referenceMonth.year,
      referenceMonth.month + 1,
    );
    final response = await dio.get(
      '/finance/transactions',
      queryParameters: {
        'startDate': startOfMonth.toIso8601String(),
        'endDate': startOfNextMonth.toIso8601String(),
      },
    );
    final data = response.data;
    final items = data is List
        ? data
        : data is Map
        ? (data['data'] ?? data['transactions'] ?? [])
        : [];

    if (items is! List) {
      return [];
    }

    return items
        .whereType<Map>()
        .map(
          (item) => TransactionModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .where(
          (item) =>
              !item.transactionDate.isBefore(startOfMonth) &&
              item.transactionDate.isBefore(startOfNextMonth),
        )
        .toList();
  }

  @override
  Future<TransactionModel> getTransaction(int id) async {
    final response = await dio.get('/finance/transactions/$id');
    return _parseTransaction(response.data);
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
    final payload = <String, dynamic>{
      'type': TransactionTypeCodec.encode(type),
      'status': TransactionStatusCodec.encode(status),
      'assetType': AssetTypeCodec.encode(assetType),
      'amountCents': amountCents,
      'categoryId': categoryId,
      'description': description,
      'transactionDate': transactionDate.toIso8601String(),
    };

    if (bankAccountId != null) {
      payload['bankAccountId'] = bankAccountId;
    }
    if (creditCardId != null) {
      payload['creditCardId'] = creditCardId;
    }
    if (installmentCount != null && installmentCount > 1) {
      payload['installmentCount'] = installmentCount;
    }

    final response = await dio.post('/finance/transactions', data: payload);
    return _parseTransaction(response.data);
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
    await createTransaction(
      type: TransactionType.expense,
      assetType: AssetType.bankAccount,
      amountCents: amountCents,
      categoryId: expenseCategoryId,
      description: description,
      transactionDate: transactionDate,
      bankAccountId: bankAccountId,
    );
    await createTransaction(
      type: TransactionType.income,
      assetType: AssetType.creditCard,
      amountCents: amountCents,
      categoryId: incomeCategoryId,
      description: description,
      transactionDate: transactionDate,
      creditCardId: creditCardId,
    );
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
      payload['transactionDate'] = transactionDate.toIso8601String();
    }
    if (scope != null) {
      payload['scope'] = TransactionMutationScopeCodec.encode(scope);
    }

    final response = await dio.patch(
      '/finance/transactions/$id',
      data: payload,
    );
    return _parseTransaction(response.data);
  }

  @override
  Future<void> deleteTransaction(
    int id, {
    TransactionMutationScope? scope,
  }) async {
    await dio.delete(
      '/finance/transactions/$id',
      data: scope == null
          ? null
          : {'scope': TransactionMutationScopeCodec.encode(scope)},
    );
  }

  TransactionModel _parseTransaction(dynamic data) {
    if (data is Map) {
      if (data['transaction'] is Map) {
        return TransactionModel.fromJson(
          Map<String, dynamic>.from(data['transaction'] as Map),
        );
      }
      if (data['data'] is Map) {
        return TransactionModel.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }

      return TransactionModel.fromJson(Map<String, dynamic>.from(data));
    }

    throw Exception('Resposta invalida da API de transacoes.');
  }
}
