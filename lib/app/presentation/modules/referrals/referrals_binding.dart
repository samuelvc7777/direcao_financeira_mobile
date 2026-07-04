import 'package:get/get.dart';

import '../../../domain/usecases/referral_use_cases.dart';
import '../../../domain/usecases/referral_settings_use_cases.dart';
import 'referrals_controller.dart';

class ReferralsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReferralsController>(
      () => ReferralsController(
        getSummaryUseCase: Get.find<GetReferralSummaryUseCase>(),
        getReferralsUseCase: Get.find<GetReferralsUseCase>(),
        getWithdrawalsUseCase: Get.find<GetPixWithdrawalsUseCase>(),
        requestPixWithdrawalUseCase: Get.find<RequestPixWithdrawalUseCase>(),
        getReferralSettingsUseCase:
            Get.isRegistered<GetReferralSettingsUseCase>()
            ? Get.find<GetReferralSettingsUseCase>()
            : null,
      ),
      fenix: true,
    );
  }
}
