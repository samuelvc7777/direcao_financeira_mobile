import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../widgets/custom_filled_button.dart';
import '../../widgets/custom_text_field.dart';
import 'login_controller.dart';
import 'widgets/login_header.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(color: context.theme.scaffoldBackgroundColor),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 40,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const LoginHeader(),
                        const SizedBox(height: 48),
                        CustomTextField(
                          controller: controller.emailController,
                          label: 'E-mail',
                          hint: 'seu@email.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        Obx(
                          () => CustomTextField(
                            controller: controller.passwordController,
                            label: 'Senha',
                            hint: '••••••',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            obscureText: !controller.isPasswordVisible.value,
                            onTogglePassword:
                                controller.togglePasswordVisibility,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: controller.openPasswordRecovery,
                            child: Text(
                              'Esqueceu a senha?',
                              style: TextStyle(color: colorScheme.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Obx(
                          () => CustomFilledButton(
                            text: 'ENTRAR NO PAINEL',
                            isLoading: controller.isLoading.value,
                            onPressed: controller.login,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Ainda não tem conta?',
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.68,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Get.toNamed(AppRoutes.register),
                              child: Text(
                                'Cadastre-se',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
