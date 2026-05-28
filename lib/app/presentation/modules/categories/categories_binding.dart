import 'package:get/get.dart';

import '../../../domain/repositories/i_category_repository.dart';
import '../../../domain/usecases/category_use_cases.dart';
import 'categories_controller.dart';

class CategoriesBinding extends Bindings {
  @override
  void dependencies() {
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
    if (!Get.isRegistered<UpdateCategoryUseCase>()) {
      Get.lazyPut(
        () => UpdateCategoryUseCase(Get.find<ICategoryRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<DeactivateCategoryUseCase>()) {
      Get.lazyPut(
        () => DeactivateCategoryUseCase(Get.find<ICategoryRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<ReactivateCategoryUseCase>()) {
      Get.lazyPut(
        () => ReactivateCategoryUseCase(Get.find<ICategoryRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<CategoriesController>()) {
      Get.lazyPut<CategoriesController>(
        () => CategoriesController(
          loadCategoriesUseCase: Get.find<LoadCategoriesUseCase>(),
          createCategoryUseCase: Get.find<CreateCategoryUseCase>(),
          updateCategoryUseCase: Get.find<UpdateCategoryUseCase>(),
          deactivateCategoryUseCase: Get.find<DeactivateCategoryUseCase>(),
          reactivateCategoryUseCase: Get.find<ReactivateCategoryUseCase>(),
        ),
      );
    }
  }
}
