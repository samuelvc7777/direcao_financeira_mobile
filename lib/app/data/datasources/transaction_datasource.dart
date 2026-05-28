import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_draft_entity.dart';
import '../models/transaction_model.dart';

abstract class ITransactionDataSource {
  Future<List<TransactionModel>> getTransactions({
    required DateTime referenceMonth,
  });
  Future<TransactionModel> getTransaction(int id);
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
  });

  Future<List<TransactionModel>> createImportedTransactions({
    required List<TransactionDraftEntity> transactions,
  });

  Future<void> createInvoicePayment({
    required int bankAccountId,
    required int creditCardId,
    required int amountCents,
    required int expenseCategoryId,
    required int incomeCategoryId,
    required String description,
    required DateTime transactionDate,
  });

  Future<TransactionModel> updateTransaction(
    int id, {
    TransactionStatus? status,
    int? categoryId,
    String? description,
    int? amountCents,
    DateTime? transactionDate,
    TransactionMutationScope? scope,
  });

  Future<void> deleteTransaction(int id, {TransactionMutationScope? scope});
}
