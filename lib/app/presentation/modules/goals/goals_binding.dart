import 'package:get/get.dart';

import '../../../core/dashboard/dashboard_refresh_notifier.dart';
import '../../../domain/repositories/i_goal_repository.dart';
import '../../../domain/usecases/goal_use_cases.dart';
import 'goals_controller.dart';

class GoalsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LoadGoalsUseCase>()) {
      Get.lazyPut(
        () => LoadGoalsUseCase(Get.find<IGoalRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<CreateGoalUseCase>()) {
      Get.lazyPut(
        () => CreateGoalUseCase(Get.find<IGoalRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<UpdateGoalUseCase>()) {
      Get.lazyPut(
        () => UpdateGoalUseCase(Get.find<IGoalRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<CompleteGoalUseCase>()) {
      Get.lazyPut(
        () => CompleteGoalUseCase(Get.find<IGoalRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<ArchiveGoalUseCase>()) {
      Get.lazyPut(
        () => ArchiveGoalUseCase(Get.find<IGoalRepository>()),
        fenix: true,
      );
    }

    Get.lazyPut<GoalsController>(
      () => GoalsController(
        loadGoalsUseCase: Get.find<LoadGoalsUseCase>(),
        createGoalUseCase: Get.find<CreateGoalUseCase>(),
        updateGoalUseCase: Get.find<UpdateGoalUseCase>(),
        completeGoalUseCase: Get.find<CompleteGoalUseCase>(),
        archiveGoalUseCase: Get.find<ArchiveGoalUseCase>(),
        dashboardRefreshNotifier: Get.find<DashboardRefreshNotifier>(),
      ),
    );
  }
}
