import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/feedback/app_snackbar.dart';
import '../../../domain/usecases/update_password_use_case.dart';
import '../../../routes/app_pages.dart';

class ResetPasswordController extends GetxController {
  ResetPasswordController({required this.updatePasswordUseCase});

  final UpdatePasswordUseCase updatePasswordUseCase;
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  void togglePasswordVisibility() => isPasswordVisible.toggle();
  void toggleConfirmPasswordVisibility() => isConfirmPasswordVisible.toggle();

  Future<void> updatePassword() async {
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      _showError('Senha obrigatoria', 'Preencha e confirme a nova senha.');
      return;
    }

    if (password != confirmPassword) {
      _showError('Senhas diferentes', 'A confirmacao precisa ser igual.');
      return;
    }

    isLoading.value = true;
    final result = await updatePasswordUseCase.execute(password);
    isLoading.value = false;

    result.fold(
      (failure) => _showError('Erro ao atualizar senha', failure.message),
      (_) {
        AppSnackbar.show(
          'Senha atualizada',
          'Agora voce ja pode entrar com a nova senha.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF03A696).withValues(alpha: 0.12),
          colorText: Colors.white,
        );
        Get.offAllNamed(AppRoutes.login);
      },
    );
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
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
