import 'package:get/get.dart';

import '../../../core/dashboard/dashboard_refresh_notifier.dart';
import '../../../core/network/realtime_client.dart';
import '../../../domain/repositories/i_auth_repository.dart';
import '../../../domain/repositories/i_bank_account_repository.dart';
import '../../../domain/repositories/i_category_repository.dart';
import '../../../domain/repositories/i_credit_card_repository.dart';
import '../../../domain/repositories/i_goal_repository.dart';
import '../../../domain/repositories/i_transaction_repository.dart';
import '../../../domain/services/invoice_payment_validator.dart';
import '../../../domain/usecases/auth_session_use_cases.dart';
import '../../../domain/usecases/bank_account_use_cases.dart';
import '../../../domain/usecases/category_use_cases.dart';
import '../../../domain/usecases/credit_card_use_cases.dart';
import '../../../domain/usecases/goal_use_cases.dart';
import '../../../domain/usecases/transaction_use_cases.dart';
import '../../../core/update/play_store_update_service.dart';
import 'home_controller.dart';
import 'home_tab_navigation.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<GetStoredUserUseCase>()) {
      Get.lazyPut(
        () => GetStoredUserUseCase(Get.find<IAuthRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<LogoutUseCase>()) {
      Get.lazyPut(
        () => LogoutUseCase(Get.find<IAuthRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<LoadBankAccountsUseCase>()) {
      Get.lazyPut(
        () => LoadBankAccountsUseCase(Get.find<IBankAccountRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<LoadCreditCardsUseCase>()) {
      Get.lazyPut(
        () => LoadCreditCardsUseCase(Get.find<ICreditCardRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<LoadCategoriesUseCase>()) {
      Get.lazyPut(
        () => LoadCategoriesUseCase(Get.find<ICategoryRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<CreateCategoryUseCase>()) {
      Get.lazyPut(
        () => CreateCategoryUseCase(Get.find<ICategoryRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<GetTransactionsUseCase>()) {
      Get.lazyPut(
        () => GetTransactionsUseCase(Get.find<ITransactionRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<CreateTransactionUseCase>()) {
      Get.lazyPut(
        () => CreateTransactionUseCase(Get.find<ITransactionRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<CreateInvoicePaymentUseCase>()) {
      Get.lazyPut(
        () => CreateInvoicePaymentUseCase(Get.find<ITransactionRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<LoadGoalsUseCase>() &&
        Get.isRegistered<IGoalRepository>()) {
      Get.lazyPut(
        () => LoadGoalsUseCase(Get.find<IGoalRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<InvoicePaymentValidator>()) {
      Get.lazyPut(() => const InvoicePaymentValidator(), fenix: true);
    }
    if (!Get.isRegistered<HomeTabNavigation>()) {
      Get.lazyPut<HomeTabNavigation>(() => GetHomeTabNavigation(), fenix: true);
    }
    if (!Get.isRegistered<AppUpdateService>()) {
      Get.lazyPut<AppUpdateService>(
        () => PlayStoreUpdateService(),
        fenix: true,
      );
    }

    if (!Get.isRegistered<HomeController>()) {
      Get.lazyPut<HomeController>(
        () => HomeController(
          getStoredUserUseCase: Get.find<GetStoredUserUseCase>(),
          logoutUseCase: Get.find<LogoutUseCase>(),
          loadBankAccountsUseCase: Get.find<LoadBankAccountsUseCase>(),
          loadCreditCardsUseCase: Get.find<LoadCreditCardsUseCase>(),
          loadCategoriesUseCase: Get.find<LoadCategoriesUseCase>(),
          createCategoryUseCase: Get.find<CreateCategoryUseCase>(),
          getTransactionsUseCase: Get.find<GetTransactionsUseCase>(),
          createInvoicePaymentUseCase: Get.find<CreateInvoicePaymentUseCase>(),
          loadGoalsUseCase: Get.isRegistered<LoadGoalsUseCase>()
              ? Get.find<LoadGoalsUseCase>()
              : null,
          invoicePaymentValidator: Get.find<InvoicePaymentValidator>(),
          dashboardRefreshNotifier: Get.find<DashboardRefreshNotifier>(),
          homeTabNavigation: Get.find<HomeTabNavigation>(),
          realtimeClient: Get.find<RealtimeClient>(),
          appUpdateService: Get.find<AppUpdateService>(),
        ),
        fenix: true,
      );
    }
  }
}
