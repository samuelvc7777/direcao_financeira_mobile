import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'register_controller.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_filled_button.dart';
import 'widgets/register_header.dart';
import 'widgets/password_requirements_panel.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
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
                      horizontal: 24.0,
                      vertical: 40.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const RegisterHeader(),
                        const SizedBox(height: 40),

                        CustomTextField(
                          controller: controller.nameController,
                          label: 'Nome Completo',
                          hint: 'Seu nome',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),

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
                            hint: 'Mínimo 8 caracteres',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            obscureText: !controller.isPasswordVisible.value,
                            onTogglePassword:
                                controller.togglePasswordVisibility,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Obx(
                          () => CustomTextField(
                            controller: controller.confirmPasswordController,
                            label: 'Confirme sua Senha',
                            hint: 'Digite a mesma senha',
                            icon: Icons.lock_reset_rounded,
                            isPassword: true,
                            obscureText:
                                !controller.isConfirmPasswordVisible.value,
                            onTogglePassword:
                                controller.toggleConfirmPasswordVisibility,
                          ),
                        ),

                        const SizedBox(height: 12),
                        const PasswordRequirementsPanel(),

                        const SizedBox(height: 32),

                        Obx(
                          () => CustomFilledButton(
                            text: 'CADASTRAR AGORA',
                            isLoading: controller.isLoading.value,
                            onPressed: controller.register,
                          ),
                        ),

                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Já possui uma conta?',
                              style: TextStyle(
                                color: context.theme.colorScheme.onSurface
                                    .withValues(alpha: 0.68),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Get.back(),
                              child: Text(
                                'Faça Login',
                                style: TextStyle(
                                  color: context.theme.colorScheme.primary,
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
