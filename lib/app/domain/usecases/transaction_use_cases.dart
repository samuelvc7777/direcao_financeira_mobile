import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/bank_account_entity.dart';
import '../entities/category_entity.dart';
import '../entities/credit_card_entity.dart';
import '../entities/transaction_draft_entity.dart';
import '../entities/transaction_entity.dart';
import '../repositories/i_bank_account_repository.dart';
import '../repositories/i_category_repository.dart';
import '../repositories/i_credit_card_repository.dart';
import '../repositories/i_transaction_repository.dart';

class GetTransactionsUseCase {
  final ITransactionRepository repository;
  GetTransactionsUseCase(this.repository);

  Future<Either<Failure, List<TransactionEntity>>> call(
    DateTime referenceMonth,
  ) async {
    return await repository.getTransactions(referenceMonth: referenceMonth);
  }
}

class GetCategoriesUseCase {
  final ICategoryRepository repository;
  GetCategoriesUseCase(this.repository);

  Future<Either<Failure, List<CategoryEntity>>> call() async {
    return await repository.getCategories();
  }
}

class GetBankAccountsUseCase {
  final IBankAccountRepository repository;
  GetBankAccountsUseCase(this.repository);

  Future<Either<Failure, List<BankAccountEntity>>> call() async {
    return await repository.getBankAccounts();
  }
}

class GetCreditCardsUseCase {
  final ICreditCardRepository repository;
  GetCreditCardsUseCase(this.repository);

  Future<Either<Failure, List<CreditCardEntity>>> call() async {
    return await repository.getCreditCards();
  }
}

class CreateTransactionUseCase {
  final ITransactionRepository repository;
  CreateTransactionUseCase(this.repository);

  Future<Either<Failure, TransactionEntity>> call({
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
    return await repository.createTransaction(
      type: type,
      status: status,
      assetType: assetType,
      amountCents: amountCents,
      categoryId: categoryId,
      description: description,
      transactionDate: transactionDate,
      bankAccountId: bankAccountId,
      creditCardId: creditCardId,
      installmentCount: installmentCount,
      recurrenceCount: recurrenceCount,
    );
  }
}

class CreateImportedTransactionsUseCase {
  final ITransactionRepository repository;

  CreateImportedTransactionsUseCase(this.repository);

  Future<Either<Failure, List<TransactionEntity>>> call({
    required List<TransactionDraftEntity> transactions,
  }) async {
    return await repository.createImportedTransactions(
      transactions: transactions,
    );
  }
}

class CreateInvoicePaymentUseCase {
  final ITransactionRepository repository;
  CreateInvoicePaymentUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required int bankAccountId,
    required int creditCardId,
    required int amountCents,
    required int expenseCategoryId,
    required int incomeCategoryId,
    required String description,
    required DateTime transactionDate,
  }) async {
    return await repository.createInvoicePayment(
      bankAccountId: bankAccountId,
      creditCardId: creditCardId,
      amountCents: amountCents,
      expenseCategoryId: expenseCategoryId,
      incomeCategoryId: incomeCategoryId,
      description: description,
      transactionDate: transactionDate,
    );
  }
}

class UpdateTransactionUseCase {
  final ITransactionRepository repository;

  UpdateTransactionUseCase(this.repository);

  Future<Either<Failure, TransactionEntity>> call(
    int id, {
    int? categoryId,
    TransactionStatus? status,
    String? description,
    int? amountCents,
    DateTime? transactionDate,
    TransactionMutationScope? scope,
  }) async {
    return await repository.updateTransaction(
      id,
      status: status,
      categoryId: categoryId,
      description: description,
      amountCents: amountCents,
      transactionDate: transactionDate,
      scope: scope,
    );
  }
}

class DeleteTransactionUseCase {
  final ITransactionRepository repository;

  DeleteTransactionUseCase(this.repository);

  Future<Either<Failure, void>> call(
    int id, {
    TransactionMutationScope? scope,
  }) async {
    return await repository.deleteTransaction(id, scope: scope);
  }
}
