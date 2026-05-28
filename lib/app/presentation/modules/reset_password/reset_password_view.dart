import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/custom_filled_button.dart';
import '../../widgets/custom_text_field.dart';
import 'reset_password_controller.dart';

class ResetPasswordView extends GetView<ResetPasswordController> {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: context.theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Icon(
                  Icons.lock_reset_rounded,
                  size: 64,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Crie uma nova senha',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Digite uma senha segura para recuperar o acesso ao app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.62),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),
                Obx(
                  () => CustomTextField(
                    controller: controller.passwordController,
                    label: 'Nova senha',
                    hint: 'Minimo 8 caracteres',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    obscureText: !controller.isPasswordVisible.value,
                    onTogglePassword: controller.togglePasswordVisibility,
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => CustomTextField(
                    controller: controller.confirmPasswordController,
                    label: 'Confirmar senha',
                    hint: 'Digite a mesma senha',
                    icon: Icons.lock_reset_rounded,
                    isPassword: true,
                    obscureText: !controller.isConfirmPasswordVisible.value,
                    onTogglePassword:
                        controller.toggleConfirmPasswordVisibility,
                  ),
                ),
                const SizedBox(height: 28),
                Obx(
                  () => CustomFilledButton(
                    text: 'SALVAR NOVA SENHA',
                    isLoading: controller.isLoading.value,
                    onPressed: controller.updatePassword,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
