import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/feedback/app_snackbar.dart';
import '../../../domain/usecases/login_use_case.dart';
import '../../../domain/usecases/send_password_reset_email_use_case.dart';
import '../../../routes/app_pages.dart';

class LoginController extends GetxController {
  LoginController({
    required this.loginUseCase,
    required this.sendPasswordResetEmailUseCase,
  });

  final LoginUseCase loginUseCase;
  final SendPasswordResetEmailUseCase sendPasswordResetEmailUseCase;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final resetEmailController = TextEditingController();
  final isLoading = false.obs;
  final isRecoveringPassword = false.obs;
  final isPasswordVisible = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    resetEmailController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() => isPasswordVisible.toggle();

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Campos Vazios', 'Por favor, preencha e-mail e senha.');
      return;
    }

    if (!GetUtils.isEmail(email)) {
      _showError('E-mail Invalido', 'O formato do e-mail nao e valido.');
      return;
    }

    isLoading.value = true;
    final result = await loginUseCase.execute(email, password);
    isLoading.value = false;

    result.fold((failure) => _showError('Erro no Login', failure.message), (
      user,
    ) {
      Get.offAllNamed(AppRoutes.initial);
      AppSnackbar.show(
        'Sucesso',
        'Bem-vindo(a), ${user.name}!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF03A696).withValues(alpha: 0.12),
        colorText: Colors.white,
      );
    });
  }

  void openPasswordRecovery() {
    resetEmailController.text = emailController.text.trim();

    Get.defaultDialog<void>(
      title: 'Recuperar senha',
      titleStyle: const TextStyle(fontWeight: FontWeight.w700),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      content: Column(
        children: [
          const Text(
            'Informe seu e-mail para receber o link de redefinicao de senha.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: resetEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              hintText: 'seu@email.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
        ],
      ),
      cancel: TextButton(
        onPressed: () => Get.back<void>(),
        child: const Text('Cancelar'),
      ),
      confirm: Obx(
        () => ElevatedButton(
          onPressed: isRecoveringPassword.value ? null : sendPasswordResetEmail,
          child: isRecoveringPassword.value
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enviar link'),
        ),
      ),
    );
  }

  Future<void> sendPasswordResetEmail() async {
    final email = resetEmailController.text.trim();

    if (!GetUtils.isEmail(email)) {
      _showError('E-mail invalido', 'Informe um e-mail valido.');
      return;
    }

    isRecoveringPassword.value = true;
    final result = await sendPasswordResetEmailUseCase.execute(email);
    isRecoveringPassword.value = false;

    result.fold(
      (failure) => _showError('Recuperacao de senha', failure.message),
      (_) {
        Get.back<void>();
        AppSnackbar.show(
          'Verifique seu e-mail',
          'Enviamos o link para redefinir sua senha.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF03A696).withValues(alpha: 0.12),
          colorText: Colors.white,
        );
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
}
