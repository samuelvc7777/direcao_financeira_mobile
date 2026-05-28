import 'package:get/get.dart';

import '../../../core/dashboard/dashboard_refresh_notifier.dart';
import '../../../domain/repositories/i_bank_account_repository.dart';
import '../../../domain/usecases/bank_account_use_cases.dart';
import 'bank_accounts_controller.dart';

class BankAccountsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LoadBankAccountsUseCase>()) {
      Get.lazyPut(
        () => LoadBankAccountsUseCase(Get.find<IBankAccountRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<CreateBankAccountUseCase>()) {
      Get.lazyPut(
        () => CreateBankAccountUseCase(Get.find<IBankAccountRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<UpdateBankAccountUseCase>()) {
      Get.lazyPut(
        () => UpdateBankAccountUseCase(Get.find<IBankAccountRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<DeactivateBankAccountUseCase>()) {
      Get.lazyPut(
        () => DeactivateBankAccountUseCase(Get.find<IBankAccountRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<ReactivateBankAccountUseCase>()) {
      Get.lazyPut(
        () => ReactivateBankAccountUseCase(Get.find<IBankAccountRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<BankAccountsController>()) {
      Get.lazyPut<BankAccountsController>(
        () => BankAccountsController(
          loadBankAccountsUseCase: Get.find<LoadBankAccountsUseCase>(),
          createBankAccountUseCase: Get.find<CreateBankAccountUseCase>(),
          updateBankAccountUseCase: Get.find<UpdateBankAccountUseCase>(),
          deactivateBankAccountUseCase:
              Get.find<DeactivateBankAccountUseCase>(),
          reactivateBankAccountUseCase:
              Get.find<ReactivateBankAccountUseCase>(),
          dashboardRefreshNotifier: Get.find<DashboardRefreshNotifier>(),
        ),
      );
    }
  }
}
