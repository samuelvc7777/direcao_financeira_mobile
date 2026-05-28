import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/transaction_draft_entity.dart';
import '../entities/transaction_entity.dart';

abstract class ITransactionRepository {
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    required DateTime referenceMonth,
  });
  Future<Either<Failure, TransactionEntity>> getTransaction(int id);
  Future<Either<Failure, TransactionEntity>> createTransaction({
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

  Future<Either<Failure, List<TransactionEntity>>> createImportedTransactions({
    required List<TransactionDraftEntity> transactions,
  });

  Future<Either<Failure, void>> createInvoicePayment({
    required int bankAccountId,
    required int creditCardId,
    required int amountCents,
    required int expenseCategoryId,
    required int incomeCategoryId,
    required String description,
    required DateTime transactionDate,
  });

  Future<Either<Failure, TransactionEntity>> updateTransaction(
    int id, {
    TransactionStatus? status,
    int? categoryId,
    String? description,
    int? amountCents,
    DateTime? transactionDate,
    TransactionMutationScope? scope,
  });

  Future<Either<Failure, void>> deleteTransaction(
    int id, {
    TransactionMutationScope? scope,
  });
}
