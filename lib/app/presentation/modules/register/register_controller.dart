import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/feedback/app_snackbar.dart';
import '../../../domain/usecases/category_use_cases.dart';
import '../../../domain/usecases/register_use_case.dart';
import '../../../routes/app_pages.dart';

class RegisterController extends GetxController {
  RegisterController({
    required this.registerUseCase,
    required this.ensureDefaultCategoriesUseCase,
  });

  final RegisterUseCase registerUseCase;
  final EnsureDefaultCategoriesUseCase ensureDefaultCategoriesUseCase;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  final hasMinLength = false.obs;
  final hasUppercase = false.obs;
  final hasLowercase = false.obs;
  final hasSpecial = false.obs;
  final passwordsMatch = false.obs;

  @override
  void onInit() {
    super.onInit();
    passwordController.addListener(_validatePassword);
    confirmPasswordController.addListener(_validatePassword);
  }

  void _validatePassword() {
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    hasMinLength.value = password.length >= 8;
    hasUppercase.value = password.contains(RegExp(r'[A-Z]'));
    hasLowercase.value = password.contains(RegExp(r'[a-z]'));
    hasSpecial.value = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    passwordsMatch.value = password.isNotEmpty && password == confirmPassword;
  }

  void togglePasswordVisibility() => isPasswordVisible.toggle();
  void toggleConfirmPasswordVisibility() => isConfirmPasswordVisible.toggle();

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showError('Erro', 'Por favor, preencha todos os campos.');
      return;
    }

    if (!passwordsMatch.value) {
      _showError('Erro', 'As senhas nao coincidem.');
      return;
    }

    isLoading.value = true;
    final result = await registerUseCase.execute(name, email, password);

    await result.fold(
      (failure) async {
        _showError('Erro no Cadastro', failure.message);
      },
      (user) async {
        final categoriesResult = await ensureDefaultCategoriesUseCase();
        categoriesResult.fold(
          (failure) {
            Get.offAllNamed(AppRoutes.initial);
            _showError(
              'Cadastro realizado',
              'Sua conta foi criada, mas nao foi possivel criar as categorias padrao: ${failure.message}',
            );
          },
          (_) {
            Get.offAllNamed(AppRoutes.initial);
            AppSnackbar.show(
              'Bem-vindo(a)!',
              'Cadastro realizado! Boas vindas, ${user.name}.',
              backgroundColor: const Color(0xFF03A696).withValues(alpha: 0.12),
              colorText: Colors.white,
            );
          },
        );
      },
    );
    isLoading.value = false;
  }

  void _showError(String title, String message) {
    AppSnackbar.show(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFBF4124).withValues(alpha: 0.12),
      colorText: Colors.white,
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
