import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/feedback/app_snackbar.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/usecases/category_use_cases.dart';

class CategoriesController extends GetxController {
  CategoriesController({
    required this.loadCategoriesUseCase,
    required this.createCategoryUseCase,
    required this.updateCategoryUseCase,
    required this.deactivateCategoryUseCase,
    required this.reactivateCategoryUseCase,
  });

  final LoadCategoriesUseCase loadCategoriesUseCase;
  final CreateCategoryUseCase createCategoryUseCase;
  final UpdateCategoryUseCase updateCategoryUseCase;
  final DeactivateCategoryUseCase deactivateCategoryUseCase;
  final ReactivateCategoryUseCase reactivateCategoryUseCase;

  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final errorMessage = RxnString();
  final categories = <CategoryEntity>[].obs;

  final colorOptions = const <String>[
    '#22c55e',
    '#038C8C',
    '#03A696',
    '#3b82f6',
    '#6366f1',
    '#f97316',
    '#ef4444',
    '#F2B366',
    '#eab308',
    '#ec4899',
  ];

  final iconOptions = const <String>[
    'briefcase',
    'fuel',
    'shopping-cart',
    'restaurant',
    'car',
    'wrench',
    'wallet',
    'credit-card',
    'chart-line',
    'home',
    'heart',
    'tag',
  ];

  List<CategoryEntity> get activeCategories =>
      categories.where((category) => category.isActive).toList();

  List<CategoryEntity> get incomeCategories =>
      categories
          .where((category) => category.type == CategoryType.income)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  List<CategoryEntity> get expenseCategories =>
      categories
          .where((category) => category.type == CategoryType.expense)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  Future<void> loadCategories() async {
    isLoading.value = true;
    errorMessage.value = null;
    final result = await loadCategoriesUseCase();

    result.fold(
      (failure) => errorMessage.value = failure.message,
      (data) => categories.assignAll(data),
    );

    isLoading.value = false;
  }

  Future<void> createCategory({
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
  }) async {
    await _runSubmission(
      action: () => createCategoryUseCase(
        name: name,
        type: type,
        color: color,
        icon: icon,
      ),
      successMessage: 'Categoria criada com sucesso.',
    );
  }

  Future<void> updateCategory({
    required int id,
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
  }) async {
    await _runSubmission(
      action: () => updateCategoryUseCase(
        id: id,
        name: name,
        type: type,
        color: color,
        icon: icon,
      ),
      successMessage: 'Categoria atualizada com sucesso.',
    );
  }

  Future<void> toggleCategoryStatus(CategoryEntity category) async {
    final isDeactivating = category.isActive;
    final actionName = isDeactivating ? 'desativar' : 'reativar';
    final actionNameCap = isDeactivating ? 'Desativar' : 'Reativar';

    final confirmed =
        await Get.dialog<bool>(
          AlertDialog(
            backgroundColor: Get.theme.colorScheme.surface,
            title: Text(
              '$actionNameCap categoria',
              style: TextStyle(color: Get.theme.colorScheme.onSurface),
            ),
            content: Text(
              'A categoria "${category.name}" sera ${actionName}ada.',
              style: TextStyle(
                color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.75),
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Get.back(result: true),
                style: FilledButton.styleFrom(
                  backgroundColor: isDeactivating
                      ? const Color(0xFFBF4124)
                      : const Color(0xFF03A696),
                ),
                child: Text(actionNameCap),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    isSubmitting.value = true;
    final result = isDeactivating
        ? await deactivateCategoryUseCase(category.id)
        : await reactivateCategoryUseCase(category.id);

    result.fold(
      (failure) => _showFeedback('Erro', failure.message, isError: true),
      (_) async {
        await loadCategories();
        if (Get.isBottomSheetOpen ?? false) {
          Get.back();
        }
        _showFeedback('Sucesso', 'Categoria ${actionName}ada com sucesso.');
      },
    );

    isSubmitting.value = false;
  }

  IconData iconForCode(String iconCode) {
    const iconMap = <String, IconData>{
      'briefcase': Icons.work_rounded,
      'fuel': Icons.local_gas_station_rounded,
      'shopping-cart': Icons.shopping_cart_rounded,
      'restaurant': Icons.restaurant_rounded,
      'car': Icons.directions_car_rounded,
      'wrench': Icons.build_rounded,
      'wallet': Icons.account_balance_wallet_rounded,
      'credit-card': Icons.credit_card_rounded,
      'chart-line': Icons.show_chart_rounded,
      'home': Icons.home_rounded,
      'heart': Icons.favorite_rounded,
      'tag': Icons.sell_rounded,
      'category': Icons.category_rounded,
    };

    return iconMap[iconCode] ?? Icons.category_rounded;
  }

  Color colorFromHex(String colorHex) {
    final normalized = colorHex.replaceFirst('#', '');
    if (normalized.length != 6) {
      return const Color(0xFF038C8C);
    }

    return Color(int.parse('FF$normalized', radix: 16));
  }

  Future<void> _runSubmission({
    required Future<dynamic> Function() action,
    required String successMessage,
  }) async {
    isSubmitting.value = true;
    final result = await action();

    result.fold(
      (failure) => _showFeedback('Erro', failure.message, isError: true),
      (_) async {
        await loadCategories();
        if (Get.isBottomSheetOpen ?? false) {
          Get.back();
        }
        _showFeedback('Sucesso', successMessage);
      },
    );

    isSubmitting.value = false;
  }

  void _showFeedback(String title, String message, {bool isError = false}) {
    AppSnackbar.show(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: isError
          ? const Color(0xFFBF4124).withValues(alpha: 0.12)
          : const Color(0xFF03A696).withValues(alpha: 0.12),
      colorText: Colors.white,
    );
  }
}
