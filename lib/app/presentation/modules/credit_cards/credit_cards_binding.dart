import 'package:get/get.dart';

import '../../../core/dashboard/dashboard_refresh_notifier.dart';
import '../../../domain/repositories/i_bank_account_repository.dart';
import '../../../domain/repositories/i_category_repository.dart';
import '../../../domain/repositories/i_credit_card_repository.dart';
import '../../../domain/repositories/i_transaction_repository.dart';
import '../../../domain/services/invoice_payment_validator.dart';
import '../../../domain/usecases/bank_account_use_cases.dart';
import '../../../domain/usecases/category_use_cases.dart';
import '../../../domain/usecases/credit_card_use_cases.dart';
import '../../../domain/usecases/invoice_notification_use_cases.dart';
import '../../../domain/usecases/transaction_use_cases.dart';
import 'credit_cards_controller.dart';

class CreditCardsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LoadCreditCardsUseCase>()) {
      Get.lazyPut(
        () => LoadCreditCardsUseCase(Get.find<ICreditCardRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<LoadBankAccountsUseCase>()) {
      Get.lazyPut(
        () => LoadBankAccountsUseCase(Get.find<IBankAccountRepository>()),
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
    if (!Get.isRegistered<CreateInvoicePaymentUseCase>()) {
      Get.lazyPut(
        () => CreateInvoicePaymentUseCase(Get.find<ITransactionRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<InvoicePaymentValidator>()) {
      Get.lazyPut(() => const InvoicePaymentValidator(), fenix: true);
    }
    if (!Get.isRegistered<CreateCreditCardUseCase>()) {
      Get.lazyPut(
        () => CreateCreditCardUseCase(Get.find<ICreditCardRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<UpdateCreditCardUseCase>()) {
      Get.lazyPut(
        () => UpdateCreditCardUseCase(Get.find<ICreditCardRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<DeactivateCreditCardUseCase>()) {
      Get.lazyPut(
        () => DeactivateCreditCardUseCase(Get.find<ICreditCardRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<ReactivateCreditCardUseCase>()) {
      Get.lazyPut(
        () => ReactivateCreditCardUseCase(Get.find<ICreditCardRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<CreditCardsController>()) {
      Get.lazyPut<CreditCardsController>(
        () => CreditCardsController(
          loadCreditCardsUseCase: Get.find<LoadCreditCardsUseCase>(),
          createCreditCardUseCase: Get.find<CreateCreditCardUseCase>(),
          updateCreditCardUseCase: Get.find<UpdateCreditCardUseCase>(),
          deactivateCreditCardUseCase: Get.find<DeactivateCreditCardUseCase>(),
          reactivateCreditCardUseCase: Get.find<ReactivateCreditCardUseCase>(),
          loadBankAccountsUseCase: Get.find<LoadBankAccountsUseCase>(),
          loadCategoriesUseCase: Get.find<LoadCategoriesUseCase>(),
          createCategoryUseCase: Get.find<CreateCategoryUseCase>(),
          createInvoicePaymentUseCase: Get.find<CreateInvoicePaymentUseCase>(),
          invoicePaymentValidator: Get.find<InvoicePaymentValidator>(),
          rescheduleInvoiceNotificationsUseCase:
              Get.isRegistered<RescheduleInvoiceNotificationsUseCase>()
              ? Get.find<RescheduleInvoiceNotificationsUseCase>()
              : null,
          dashboardRefreshNotifier: Get.find<DashboardRefreshNotifier>(),
        ),
      );
    }
  }
}
