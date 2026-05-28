import 'package:dartz/dartz.dart';
import 'package:direcao_financeira_mobile/app/core/dashboard/dashboard_refresh_notifier.dart';
import 'package:direcao_financeira_mobile/app/core/errors/failures.dart';
import 'package:direcao_financeira_mobile/app/core/network/realtime_client.dart';
import 'package:direcao_financeira_mobile/app/core/update/play_store_update_service.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/bank_account_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/category_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/credit_card_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/transaction_draft_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/transaction_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/user_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_auth_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_bank_account_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_category_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_credit_card_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_transaction_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/services/invoice_payment_validator.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/auth_session_use_cases.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/bank_account_use_cases.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/category_use_cases.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/credit_card_use_cases.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/transaction_use_cases.dart';
import 'package:direcao_financeira_mobile/app/presentation/modules/home/home_controller.dart';
import 'package:direcao_financeira_mobile/app/presentation/modules/home/home_tab_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeAuthRepository implements IAuthRepository {
  @override
  Either<Failure, UserEntity?> getStoredUser() => Right(
    UserEntity(
      id: 1,
      name: 'Samuel',
      email: 'samuel@test.com',
      role: 'user',
      isActive: true,
    ),
  );

  @override
  Future<Either<Failure, String?>> getToken() async => const Right(null);

  @override
  Future<Either<Failure, UserEntity>> login(
    String email,
    String password,
  ) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> logout() async => const Right(null);

  @override
  Future<Either<Failure, UserEntity>> register(
    String name,
    String email,
    String password,
  ) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> updatePassword(String password) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, UserEntity>> updateProfilePhotoBase64(
    String? profilePhotoBase64,
  ) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> saveToken(String token) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> saveUser(UserEntity user) async =>
      const Right(null);
}

class _FakeBankAccountRepository implements IBankAccountRepository {
  @override
  Future<Either<Failure, List<BankAccountEntity>>> getBankAccounts() async =>
      const Right([]);

  @override
  Future<Either<Failure, BankAccountEntity>> createBankAccount({
    required String name,
    required String bankName,
    required String color,
    required AccountType accountType,
    required int initialBalanceCents,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> deactivateBankAccount(int id) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> reactivateBankAccount(int id) async =>
      const Right(null);

  @override
  Future<Either<Failure, BankAccountEntity>> updateBankAccount({
    required int id,
    required String name,
    required String bankName,
    required String color,
    required AccountType accountType,
    required int initialBalanceCents,
    bool? isActive,
  }) async => throw UnimplementedError();
}

class _FakeCreditCardRepository implements ICreditCardRepository {
  List<CreditCardEntity> cards = const [];

  @override
  Future<Either<Failure, List<CreditCardEntity>>> getCreditCards() async =>
      Right(cards);

  @override
  Future<Either<Failure, CreditCardEntity>> createCreditCard({
    required String name,
    required String brand,
    required String color,
    required int limitCents,
    required int closingDay,
    required int dueDay,
    required String lastFourDigits,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> deactivateCreditCard(int id) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> reactivateCreditCard(int id) async =>
      const Right(null);

  @override
  Future<Either<Failure, CreditCardEntity>> updateCreditCard({
    required int id,
    required String name,
    required String brand,
    required String color,
    required int limitCents,
    required int closingDay,
    required int dueDay,
    required String lastFourDigits,
    bool? isActive,
  }) async => throw UnimplementedError();
}

class _FakeCategoryRepository implements ICategoryRepository {
  List<CategoryEntity> categories = [];
  int nextId = 100;

  @override
  Future<Either<Failure, CategoryEntity>> createCategory({
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
  }) async {
    final category = CategoryEntity(
      id: nextId++,
      userId: 1,
      name: name,
      type: type,
      color: color,
      icon: icon,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    categories = [...categories, category];
    return Right(category);
  }

  @override
  Future<Either<Failure, void>> deactivateCategory(int id) async =>
      const Right(null);

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async =>
      Right(categories);

  @override
  Future<Either<Failure, void>> reactivateCategory(int id) async =>
      const Right(null);

  @override
  Future<Either<Failure, CategoryEntity>> updateCategory({
    required int id,
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
  }) async => throw UnimplementedError();
}

class _FakeTransactionRepository implements ITransactionRepository {
  final List<DateTime> requestedMonths = [];
  List<TransactionEntity> response = [];
  final List<Map<String, dynamic>> createdTransactions = [];

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    required DateTime referenceMonth,
  }) async {
    requestedMonths.add(referenceMonth);
    return Right(response);
  }

  @override
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
  }) async {
    createdTransactions.add({
      'type': type,
      'status': status,
      'assetType': assetType,
      'amountCents': amountCents,
      'categoryId': categoryId,
      'description': description,
      'transactionDate': transactionDate,
      'bankAccountId': bankAccountId,
      'creditCardId': creditCardId,
      'installmentCount': installmentCount,
    });

    return Right(
      TransactionEntity(
        id: createdTransactions.length,
        type: type,
        status: status,
        assetType: assetType,
        amountCents: amountCents,
        categoryId: categoryId,
        description: description,
        transactionDate: transactionDate,
        bankAccountId: bankAccountId,
        creditCardId: creditCardId,
      ),
    );
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> createImportedTransactions({
    required List<TransactionDraftEntity> transactions,
  }) async {
    final created = transactions.asMap().entries.map((entry) {
      final index = entry.key;
      final draft = entry.value;
      return TransactionEntity(
        id: 1000 + index,
        type: draft.type,
        status: TransactionStatus.cleared,
        assetType: draft.assetType,
        amountCents: draft.amountCents,
        categoryId: draft.categoryId,
        description: draft.description,
        transactionDate: draft.transactionDate,
        bankAccountId: draft.bankAccountId,
        creditCardId: draft.creditCardId,
      );
    }).toList();

    return Right(created);
  }

  @override
  Future<Either<Failure, void>> createInvoicePayment({
    required int bankAccountId,
    required int creditCardId,
    required int amountCents,
    required int expenseCategoryId,
    required int incomeCategoryId,
    required String description,
    required DateTime transactionDate,
  }) async {
    createdTransactions.add({
      'type': TransactionType.expense,
      'assetType': AssetType.bankAccount,
      'amountCents': amountCents,
      'categoryId': expenseCategoryId,
      'description': description,
      'transactionDate': transactionDate,
      'bankAccountId': bankAccountId,
      'creditCardId': null,
    });
    createdTransactions.add({
      'type': TransactionType.income,
      'assetType': AssetType.creditCard,
      'amountCents': amountCents,
      'categoryId': incomeCategoryId,
      'description': description,
      'transactionDate': transactionDate,
      'bankAccountId': null,
      'creditCardId': creditCardId,
    });

    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(
    int id, {
    TransactionMutationScope? scope,
  }) async => const Right(null);

  @override
  Future<Either<Failure, TransactionEntity>> getTransaction(int id) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, TransactionEntity>> updateTransaction(
    int id, {
    TransactionStatus? status,
    int? categoryId,
    String? description,
    int? amountCents,
    DateTime? transactionDate,
    TransactionMutationScope? scope,
  }) async => throw UnimplementedError();
}

class _FakeHomeTabNavigation implements HomeTabNavigation {
  @override
  void openTransactionsTab() {}
}

class _FakeAppUpdateService implements AppUpdateService {
  bool available = false;
  bool openStoreCalled = false;

  @override
  Future<bool> hasUpdateAvailable() async => available;

  @override
  Future<bool> openStorePage() async {
    openStoreCalled = true;
    return true;
  }
}

class _FakeRealtimeClient implements RealtimeClient {
  @override
  final RxBool isOnline = true.obs;
  final handlers = <String, void Function(dynamic payload)>{};

  @override
  void connect({required String token}) {}

  @override
  Future<void> dispose() async {}

  @override
  void disconnect() {}

  @override
  void off(String event, [void Function(dynamic payload)? handler]) {
    if (handler == null || handlers[event] == handler) {
      handlers.remove(event);
    }
  }

  @override
  void on(String event, void Function(dynamic payload) handler) {
    handlers[event] = handler;
  }

  void emit(String event, [dynamic payload]) {
    handlers[event]?.call(payload);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeController', () {
    late _FakeTransactionRepository transactionRepository;
    late _FakeCategoryRepository categoryRepository;
    late _FakeCreditCardRepository creditCardRepository;
    late _FakeAppUpdateService appUpdateService;
    late _FakeRealtimeClient realtimeClient;
    late HomeController controller;

    setUp(() {
      Get.testMode = true;
      transactionRepository = _FakeTransactionRepository()
        ..response = [
          TransactionEntity(
            id: 1,
            type: TransactionType.expense,
            status: TransactionStatus.cleared,
            assetType: AssetType.bankAccount,
            amountCents: 5000,
            categoryId: 7,
            description: 'Combustivel',
            transactionDate: DateTime(2026, 3, 10),
            categoryName: 'Combustivel',
            categoryColor: '#FFAA00',
          ),
        ];
      categoryRepository = _FakeCategoryRepository();
      creditCardRepository = _FakeCreditCardRepository();
      appUpdateService = _FakeAppUpdateService();
      realtimeClient = _FakeRealtimeClient();
      controller = HomeController(
        getStoredUserUseCase: GetStoredUserUseCase(_FakeAuthRepository()),
        logoutUseCase: LogoutUseCase(_FakeAuthRepository()),
        loadBankAccountsUseCase: LoadBankAccountsUseCase(
          _FakeBankAccountRepository(),
        ),
        loadCreditCardsUseCase: LoadCreditCardsUseCase(creditCardRepository),
        loadCategoriesUseCase: LoadCategoriesUseCase(categoryRepository),
        createCategoryUseCase: CreateCategoryUseCase(categoryRepository),
        getTransactionsUseCase: GetTransactionsUseCase(transactionRepository),
        createInvoicePaymentUseCase: CreateInvoicePaymentUseCase(
          transactionRepository,
        ),
        invoicePaymentValidator: const InvoicePaymentValidator(),
        dashboardRefreshNotifier: DefaultDashboardRefreshNotifier(),
        homeTabNavigation: _FakeHomeTabNavigation(),
        realtimeClient: realtimeClient,
        appUpdateService: appUpdateService,
      );
    });

    test('carrega transacoes usando o mes selecionado', () async {
      final selectedMonth = DateTime(2026, 3, 1);
      controller.selectedMonth.value = selectedMonth;

      await controller.loadDashboardData();

      expect(transactionRepository.requestedMonths, [selectedMonth]);
    });

    test(
      'previousMonth e nextMonth mudam o mes e fazem nova carga remota',
      () async {
        controller.selectedMonth.value = DateTime(2026, 3, 1);

        await controller.previousMonth();
        await controller.nextMonth();

        expect(transactionRepository.requestedMonths, [
          DateTime(2026, 2, 1),
          DateTime(2026, 3, 1),
        ]);
      },
    );

    test('loadDashboardData usa o mes informado como referencia', () async {
      controller.selectedMonth.value = DateTime(2026, 5, 1);

      final pendingLoad = controller.loadDashboardData(
        referenceMonth: DateTime(2026, 4, 1),
        silent: true,
      );
      controller.selectedMonth.value = DateTime(2026, 6, 1);

      await pendingLoad;

      expect(transactionRepository.requestedMonths, [DateTime(2026, 4, 1)]);
    });

    test(
      'gera o grafico a partir das despesas do retorno mensal sem placeholder',
      () async {
        await controller.loadDashboardData();

        expect(controller.gastosPorCategoria, isNotEmpty);
        expect(
          controller.gastosPorCategoria.single.categoryLabel,
          'Combustivel',
        );
        expect(controller.gastosPorCategoria.single.amountCents, 5000);
      },
    );

    test(
      'recarrega gastos por categoria em eventos realtime de transacao',
      () async {
        controller.onInit();
        await Future<void>.delayed(Duration.zero);

        transactionRepository.requestedMonths.clear();
        transactionRepository.response = [
          TransactionEntity(
            id: 2,
            type: TransactionType.expense,
            status: TransactionStatus.cleared,
            assetType: AssetType.bankAccount,
            amountCents: 7500,
            categoryId: 9,
            description: 'Mercado',
            transactionDate: DateTime(2026, 3, 12),
            categoryName: 'Mercado',
            categoryColor: '#10B981',
          ),
        ];

        realtimeClient.emit('transaction.updated');
        await Future<void>.delayed(const Duration(milliseconds: 900));

        expect(transactionRepository.requestedMonths, isNotEmpty);
        expect(controller.gastosPorCategoria.single.categoryLabel, 'Mercado');
        expect(controller.gastosPorCategoria.single.amountCents, 7500);

        controller.onClose();
        expect(realtimeClient.handlers, isEmpty);
      },
    );

    test('ignora pagamento interno de fatura nos resumos da home', () async {
      transactionRepository.response = [
        TransactionEntity(
          id: 1,
          type: TransactionType.expense,
          status: TransactionStatus.cleared,
          assetType: AssetType.bankAccount,
          amountCents: 9000,
          categoryId: 7,
          description: 'Mercado',
          transactionDate: DateTime(2026, 3, 10),
        ),
        TransactionEntity(
          id: 2,
          type: TransactionType.expense,
          status: TransactionStatus.cleared,
          assetType: AssetType.bankAccount,
          amountCents: 5000,
          categoryId: 99,
          description: '${kInternalInvoicePaymentDescriptionPrefix}1:1',
          transactionDate: DateTime(2026, 3, 11),
        ),
      ];

      await controller.loadDashboardData();

      expect(controller.ultimasTransacoes, hasLength(1));
      expect(controller.saidas, 90.0);
    });

    test('paga a fatura criando saida na conta e entrada no cartao', () async {
      controller.contas.assignAll([
        BankAccountEntity(
          id: 10,
          name: 'Conta Principal',
          bankName: 'Nubank',
          color: '#123456',
          accountType: AccountType.checking,
          initialBalanceCents: 200000,
          currentBalanceCents: 200000,
          isActive: true,
        ),
      ]);
      final card = CreditCardEntity(
        id: 20,
        name: 'Visa',
        brand: 'visa',
        color: '#654321',
        limitCents: 500000,
        availableLimitCents: 300000,
        closingDay: 10,
        dueDay: 20,
        lastFourDigits: '1234',
        isActive: true,
        closedInvoiceCents: 120000,
        payableInvoiceCents: 120000,
        nextDueDate: DateTime(2026, 3, 25),
        isInvoiceDueToday: true,
      );

      await controller.payInvoice(
        card: card,
        bankAccount: controller.contas.first,
      );

      expect(transactionRepository.createdTransactions, hasLength(2));
      expect(
        transactionRepository.createdTransactions.first['assetType'],
        AssetType.bankAccount,
      );
      expect(
        transactionRepository.createdTransactions.first['type'],
        TransactionType.expense,
      );
      expect(
        transactionRepository.createdTransactions.last['assetType'],
        AssetType.creditCard,
      );
      expect(
        transactionRepository.createdTransactions.last['type'],
        TransactionType.income,
      );
      expect(categoryRepository.categories, hasLength(2));
    });

    test('paga fatura parcial usando o valor validado', () async {
      final account = BankAccountEntity(
        id: 10,
        name: 'Conta Principal',
        bankName: 'Nubank',
        color: '#123456',
        accountType: AccountType.checking,
        initialBalanceCents: 200000,
        currentBalanceCents: 200000,
        isActive: true,
      );
      final card = CreditCardEntity(
        id: 20,
        name: 'Visa',
        brand: 'visa',
        color: '#654321',
        limitCents: 500000,
        availableLimitCents: 300000,
        closingDay: 10,
        dueDay: 20,
        lastFourDigits: '1234',
        isActive: true,
        closedInvoiceCents: 120000,
        payableInvoiceCents: 120000,
        nextDueDate: DateTime(2026, 3, 25),
      );

      final error = await controller.submitInvoicePayment(
        card: card,
        bankAccount: account,
        mode: InvoicePaymentMode.partial,
        amountCents: 45000,
      );

      expect(error, isNull);
      expect(transactionRepository.createdTransactions, hasLength(2));
      expect(
        transactionRepository.createdTransactions.first['amountCents'],
        45000,
      );
      expect(
        transactionRepository.createdTransactions.last['amountCents'],
        45000,
      );
    });

    test('bloqueia pagamento parcial igual ao saldo em aberto', () async {
      final account = BankAccountEntity(
        id: 10,
        name: 'Conta Principal',
        bankName: 'Nubank',
        color: '#123456',
        accountType: AccountType.checking,
        initialBalanceCents: 200000,
        currentBalanceCents: 200000,
        isActive: true,
      );
      final card = CreditCardEntity(
        id: 20,
        name: 'Visa',
        brand: 'visa',
        color: '#654321',
        limitCents: 500000,
        availableLimitCents: 300000,
        closingDay: 10,
        dueDay: 20,
        lastFourDigits: '1234',
        isActive: true,
        closedInvoiceCents: 120000,
        payableInvoiceCents: 120000,
      );

      final error = await controller.submitInvoicePayment(
        card: card,
        bankAccount: account,
        mode: InvoicePaymentMode.partial,
        amountCents: 120000,
      );

      expect(
        error,
        'O pagamento parcial deve ser menor que o saldo em aberto.',
      );
      expect(transactionRepository.createdTransactions, isEmpty);
    });

    test('carrega estado de update disponivel na abertura', () async {
      appUpdateService.available = true;

      controller.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(controller.isUpdateAvailable.value, isTrue);

      controller.onClose();
    });

    test('abre a loja quando o usuario toca no botao de atualizar', () async {
      await controller.openAppStore();

      expect(appUpdateService.openStoreCalled, isTrue);
    });
  });
}
