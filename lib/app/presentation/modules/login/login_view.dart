import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../widgets/auth_primary_button.dart';
import '../../widgets/auth_text_field.dart';
import 'login_controller.dart';
import 'widgets/login_header.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF0B1120)
        : const Color(0xFFF8FAFC);
    final secondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final primary = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E40AF);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 257, child: LoginHeader()),
                      const SizedBox(height: 28),
                      AuthTextField(
                        controller: controller.emailController,
                        label: 'E-mail',
                        hint: 'seu@email.com',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      Obx(
                        () => AuthTextField(
                          controller: controller.passwordController,
                          label: 'Senha',
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          obscureText: !controller.isPasswordVisible.value,
                          onTogglePassword: controller.togglePasswordVisibility,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: controller.openPasswordRecovery,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Esqueceu a senha?',
                            style: TextStyle(
                              color: primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Obx(
                        () => AuthPrimaryButton(
                          label: 'ENTRAR',
                          isLoading: controller.isLoading.value,
                          onPressed: () => _submit(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () => Get.toNamed(AppRoutes.register),
                        child: Text(
                          'Ainda não tem conta? Cadastre-se',
                          style: TextStyle(
                            color: secondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    await controller.login();
  }
}
