import 'package:direcao_financeira_mobile/app/core/errors/failures.dart';
import 'package:direcao_financeira_mobile/app/core/network/api_error_mapper.dart';
import 'package:direcao_financeira_mobile/app/core/network/api_request_logger.dart';
import 'package:direcao_financeira_mobile/app/data/datasources/bank_account_datasource.dart';
import 'package:direcao_financeira_mobile/app/data/datasources/category_datasource.dart';
import 'package:direcao_financeira_mobile/app/data/datasources/credit_card_datasource.dart';
import 'package:direcao_financeira_mobile/app/data/datasources/transaction_datasource.dart';
import 'package:direcao_financeira_mobile/app/data/models/bank_account_model.dart';
import 'package:direcao_financeira_mobile/app/data/models/category_model.dart';
import 'package:direcao_financeira_mobile/app/data/models/credit_card_model.dart';
import 'package:direcao_financeira_mobile/app/data/models/transaction_model.dart';
import 'package:direcao_financeira_mobile/app/data/repositories/bank_account_repository.dart';
import 'package:direcao_financeira_mobile/app/data/repositories/category_repository.dart';
import 'package:direcao_financeira_mobile/app/data/repositories/credit_card_repository.dart';
import 'package:direcao_financeira_mobile/app/data/repositories/transaction_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/bank_account_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/category_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/transaction_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/transaction_draft_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/dio_test_helpers.dart';
import '../../support/test_entities.dart';

ApiRequestLogger _buildLogger() {
  return ApiRequestLogger(apiErrorMapper: const ApiErrorMapper());
}

class _FakeBankAccountDataSource implements IBankAccountDataSource {
  List<BankAccountModel> accounts = [];
  Object? error;

  @override
  Future<BankAccountModel> createBankAccount({
    required String name,
    required String bankName,
    required String color,
    required AccountType accountType,
    required int initialBalanceCents,
  }) async {
    final created = BankAccountModel(
      id: accounts.isEmpty ? 1 : accounts.last.id + 1,
      name: name,
      bankName: bankName,
      color: color,
      accountType: accountType,
      initialBalanceCents: initialBalanceCents,
      currentBalanceCents: initialBalanceCents,
      isActive: true,
    );
    accounts = [...accounts, created];
    return created;
  }

  @override
  Future<void> deactivateBankAccount(int id) async {
    accounts = [
      for (final account in accounts)
        if (account.id == id)
          BankAccountModel(
            id: account.id,
            name: account.name,
            bankName: account.bankName,
            color: account.color,
            accountType: account.accountType,
            initialBalanceCents: account.initialBalanceCents,
            currentBalanceCents: account.currentBalanceCents,
            isActive: false,
          )
        else
          account,
    ];
  }

  @override
  Future<List<BankAccountModel>> getBankAccounts() async {
    if (error != null) {
      throw error!;
    }
    return accounts;
  }

  @override
  Future<void> reactivateBankAccount(int id) async {
    accounts = [
      for (final account in accounts)
        if (account.id == id)
          BankAccountModel(
            id: account.id,
            name: account.name,
            bankName: account.bankName,
            color: account.color,
            accountType: account.accountType,
            initialBalanceCents: account.initialBalanceCents,
            currentBalanceCents: account.currentBalanceCents,
            isActive: true,
          )
        else
          account,
    ];
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
    final updated = BankAccountModel(
      id: id,
      name: name,
      bankName: bankName,
      color: color,
      accountType: accountType,
      initialBalanceCents: initialBalanceCents,
      currentBalanceCents: initialBalanceCents,
      isActive: isActive ?? true,
    );
    accounts = [
      for (final account in accounts)
        if (account.id == id) updated else account,
    ];
    return updated;
  }
}

class _FakeCategoryDataSource implements ICategoryDataSource {
  List<CategoryModel> categories = [];
  Object? error;

  @override
  Future<CategoryModel> createCategory({
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
  }) async => buildCategory(name: name, type: type);

  @override
  Future<void> deactivateCategory(int id) async {}

  @override
  Future<List<CategoryModel>> getCategories() async {
    if (error != null) {
      throw error!;
    }
    return categories;
  }

  @override
  Future<void> reactivateCategory(int id) async {}

  @override
  Future<CategoryModel> updateCategory({
    required int id,
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
  }) async => buildCategory(id: id, name: name, type: type);
}

class _FakeCreditCardDataSource implements ICreditCardDataSource {
  List<CreditCardModel> cards = [];
  Object? error;

  @override
  Future<CreditCardModel> createCreditCard({
    required String name,
    required String brand,
    required String color,
    required int limitCents,
    required int closingDay,
    required int dueDay,
    required String lastFourDigits,
  }) async => buildCreditCard(name: name);

  @override
  Future<void> deactivateCreditCard(int id) async {}

  @override
  Future<List<CreditCardModel>> getCreditCards() async {
    if (error != null) {
      throw error!;
    }
    return cards;
  }

  @override
  Future<void> reactivateCreditCard(int id) async {}

  @override
  Future<CreditCardModel> updateCreditCard({
    required int id,
    required String name,
    required String brand,
    required String color,
    required int limitCents,
    required int closingDay,
    required int dueDay,
    required String lastFourDigits,
    bool? isActive,
  }) async => buildCreditCard(id: id, name: name, isActive: isActive ?? true);
}

class _FakeTransactionDataSource implements ITransactionDataSource {
  List<TransactionModel> transactions = [];
  Object? error;

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
  }) async => buildTransaction(
    id: 10,
    type: type,
    status: status,
    date: transactionDate,
  );

  @override
  Future<List<TransactionModel>> createImportedTransactions({
    required List<TransactionDraftEntity> transactions,
  }) async => transactions
      .map(
        (draft) => buildTransaction(
          id: draft.amountCents,
          type: draft.type,
          date: draft.transactionDate,
          description: draft.description,
        ),
      )
      .toList();

  @override
  Future<void> deleteTransaction(
    int id, {
    TransactionMutationScope? scope,
  }) async {}

  @override
  Future<TransactionModel> getTransaction(int id) async {
    if (error != null) {
      throw error!;
    }
    return transactions.first;
  }

  @override
  Future<List<TransactionModel>> getTransactions({
    required DateTime referenceMonth,
  }) async {
    if (error != null) {
      throw error!;
    }
    return transactions;
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
  }) async {}

  @override
  Future<TransactionModel> updateTransaction(
    int id, {
    TransactionStatus? status,
    int? categoryId,
    String? description,
    int? amountCents,
    DateTime? transactionDate,
    TransactionMutationScope? scope,
  }) async => buildTransaction(
    id: id,
    status: status ?? TransactionStatus.cleared,
    date: transactionDate,
  );
}

void main() {
  group('BankAccountRepository', () {
    late _FakeBankAccountDataSource dataSource;
    late BankAccountRepository repository;

    setUp(() {
      dataSource = _FakeBankAccountDataSource()
        ..accounts = [buildBankAccount()];
      repository = BankAccountRepository(
        dataSource: dataSource,
        apiErrorMapper: const ApiErrorMapper(),
        apiRequestLogger: _buildLogger(),
      );
    });

    test('sucesso retorna contas', () async {
      final result = await repository.getBankAccounts();
      expect(result.isRight(), isTrue);
    });

    test('dio com message da API retorna essa message', () async {
      dataSource.error = dioBadResponse(
        statusCode: 400,
        data: {'message': 'Conta invalida'},
        path: '/finance/bank-accounts',
      );

      final result = await repository.getBankAccounts();

      expect(
        result.swap().getOrElse(() => ServerFailure('x')).message,
        'Conta invalida',
      );
    });

    test('dio sem message usa fallback', () async {
      dataSource.error = dioBadResponse(
        statusCode: 500,
        data: {'error': 'boom'},
        path: '/finance/bank-accounts',
      );

      final result = await repository.getBankAccounts();

      expect(
        result.swap().getOrElse(() => ServerFailure('x')).message,
        'Erro ao carregar contas bancarias.',
      );
    });

    test('falha inesperada usa fallback inesperado', () async {
      dataSource.error = Exception('erro inesperado');

      final result = await repository.getBankAccounts();

      expect(
        result.swap().getOrElse(() => ServerFailure('x')).message,
        'Erro inesperado ao carregar contas bancarias.',
      );
    });

    test('migra usuarios antigos criando a conta Dinheiro padrao', () async {
      dataSource.accounts = [buildBankAccount(id: 1, isActive: true)];
      dataSource.accounts = dataSource.accounts
          .where((account) => account.accountType != AccountType.wallet)
          .toList();

      final result = await repository.getBankAccounts();
      final accounts = result.getOrElse(() => const []);

      expect(
        accounts.any((account) => account.accountType == AccountType.wallet),
        isTrue,
      );
      expect(
        accounts
            .firstWhere((account) => account.accountType == AccountType.wallet)
            .name,
        'Dinheiro',
      );
    });

    test('reativa conta Dinheiro legada quando esta inativa', () async {
      dataSource.accounts = [
        BankAccountModel(
          id: 10,
          name: 'Dinheiro',
          bankName: 'Dinheiro',
          color: '#06B6D4',
          accountType: AccountType.wallet,
          initialBalanceCents: 0,
          currentBalanceCents: 0,
          isActive: false,
        ),
      ];

      final result = await repository.getBankAccounts();
      final accounts = result.getOrElse(() => const []);

      expect(accounts.single.isActive, isTrue);
      expect(accounts.single.accountType, AccountType.wallet);
    });
  });

  group('CategoryRepository', () {
    late _FakeCategoryDataSource dataSource;
    late CategoryRepository repository;

    setUp(() {
      dataSource = _FakeCategoryDataSource()..categories = [buildCategory()];
      repository = CategoryRepository(
        dataSource: dataSource,
        apiErrorMapper: const ApiErrorMapper(),
        apiRequestLogger: _buildLogger(),
      );
    });

    test('sucesso retorna categorias', () async {
      final result = await repository.getCategories();
      expect(result.isRight(), isTrue);
    });

    test('dio com message da API retorna essa message', () async {
      dataSource.error = dioBadResponse(
        statusCode: 400,
        data: {
          'message': ['Categoria duplicada'],
        },
        path: '/finance/categories',
      );

      final result = await repository.getCategories();

      expect(
        result.swap().getOrElse(() => ServerFailure('x')).message,
        'Categoria duplicada',
      );
    });

    test('dio sem message usa fallback', () async {
      dataSource.error = dioBadResponse(
        statusCode: 500,
        data: {'error': 'boom'},
        path: '/finance/categories',
      );

      final result = await repository.getCategories();

      expect(
        result.swap().getOrElse(() => ServerFailure('x')).message,
        'Erro ao carregar categorias.',
      );
    });

    test('falha inesperada usa fallback inesperado', () async {
      dataSource.error = Exception('erro inesperado');

      final result = await repository.getCategories();

      expect(
        result.swap().getOrElse(() => ServerFailure('x')).message,
        'Erro inesperado ao carregar categorias.',
      );
    });
  });

  group('CreditCardRepository', () {
    late _FakeCreditCardDataSource dataSource;
    late CreditCardRepository repository;

    setUp(() {
      dataSource = _FakeCreditCardDataSource()..cards = [buildCreditCard()];
      repository = CreditCardRepository(
        dataSource: dataSource,
        apiErrorMapper: const ApiErrorMapper(),
        apiRequestLogger: _buildLogger(),
      );
    });

    test('sucesso retorna cartoes', () async {
      final result = await repository.getCreditCards();
      expect(result.isRight(), isTrue);
    });

    test('dio com message da API retorna essa message', () async {
      dataSource.error = dioBadResponse(
        statusCode: 400,
        data: {'message': 'Cartao invalido'},
        path: '/finance/credit-cards',
      );

      final result = await repository.getCreditCards();

      expect(
        result.swap().getOrElse(() => ServerFailure('x')).message,
        'Cartao invalido',
      );
    });

    test('dio sem message usa fallback', () async {
      dataSource.error = dioBadResponse(
        statusCode: 500,
        data: {'error': 'boom'},
        path: '/finance/credit-cards',
      );

      final result = await repository.getCreditCards();

      expect(
        result.swap().getOrElse(() => ServerFailure('x')).message,
        'Erro ao carregar cartoes de credito.',
      );
    });

    test('falha inesperada usa fallback inesperado', () async {
      dataSource.error = Exception('erro inesperado');

      final result = await repository.getCreditCards();

      expect(
        result.swap().getOrElse(() => ServerFailure('x')).message,
        'Erro inesperado ao carregar cartoes de credito.',
      );
    });
  });

  group('TransactionRepository', () {
    late _FakeTransactionDataSource dataSource;
    late TransactionRepository repository;

    setUp(() {
      dataSource = _FakeTransactionDataSource()
        ..transactions = [buildTransaction()];
      repository = TransactionRepository(
        dataSource: dataSource,
        apiErrorMapper: const ApiErrorMapper(),
        apiRequestLogger: _buildLogger(),
      );
    });

    test('sucesso retorna transacoes', () async {
      final result = await repository.getTransactions(
        referenceMonth: DateTime(2026, 3),
      );
      expect(result.isRight(), isTrue);
    });

    test('dio com message da API retorna essa message', () async {
      dataSource.error = dioBadResponse(
        statusCode: 400,
        data: {'message': 'Periodo invalido'},
        path: '/finance/transactions',
      );

      final result = await repository.getTransactions(
        referenceMonth: DateTime(2026, 3),
      );

      expect(
        result.swap().getOrElse(() => ServerFailure('x')).message,
        'Periodo invalido',
      );
    });

    test('dio sem message usa fallback', () async {
      dataSource.error = dioBadResponse(
        statusCode: 500,
        data: {'error': 'boom'},
        path: '/finance/transactions',
      );

      final result = await repository.getTransactions(
        referenceMonth: DateTime(2026, 3),
      );

      expect(
        result.swap().getOrElse(() => ServerFailure('x')).message,
        'Erro ao carregar transacoes.',
      );
    });

    test('falha inesperada usa fallback inesperado', () async {
      dataSource.error = Exception('erro inesperado');

      final result = await repository.getTransactions(
        referenceMonth: DateTime(2026, 3),
      );

      expect(
        result.swap().getOrElse(() => ServerFailure('x')).message,
        'Erro inesperado ao carregar transacoes.',
      );
    });
  });
}
