import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../widgets/auth_primary_button.dart';
import '../../widgets/auth_sensitive_data_consent_sheet.dart';
import '../../widgets/auth_text_field.dart';
import '../../formatters/br_text_input_formatters.dart';
import 'register_controller.dart';
import 'widgets/password_requirements_panel.dart';
import 'widgets/register_header.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF0B1120)
        : const Color(0xFFF8FAFC);
    final secondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 247, child: RegisterHeader()),
                    const SizedBox(height: 22),
                    AuthTextField(
                      controller: controller.nameController,
                      label: 'Nome completo',
                      hint: 'Seu nome',
                      icon: Icons.person_outline_rounded,
                      height: 60,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    AuthTextField(
                      controller: controller.emailController,
                      label: 'E-mail',
                      hint: 'seu@email.com',
                      icon: Icons.mail_outline_rounded,
                      height: 60,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    AuthTextField(
                      controller: controller.phoneController,
                      label: 'Telefone',
                      hint: '(11) 99999-9999',
                      icon: Icons.phone_android_rounded,
                      height: 60,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        DigitsMaskTextInputFormatter('(##) #####-####'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => controller.showReferralCodeInput.value
                          ? Column(
                              children: [
                                AuthTextField(
                                  controller: controller.referralCodeController,
                                  label: 'Codigo de indicacao',
                                  hint: 'Opcional',
                                  icon: Icons.card_giftcard_rounded,
                                  height: 60,
                                  keyboardType: TextInputType.text,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                    Obx(
                      () => AuthTextField(
                        controller: controller.passwordController,
                        label: 'Senha',
                        hint: 'Mínimo 8 caracteres',
                        icon: Icons.lock_outline_rounded,
                        height: 60,
                        obscureText: !controller.isPasswordVisible.value,
                        onTogglePassword: controller.togglePasswordVisibility,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => AuthTextField(
                        controller: controller.confirmPasswordController,
                        label: 'Confirme sua senha',
                        hint: 'Digite a mesma senha',
                        icon: Icons.sync_rounded,
                        height: 60,
                        obscureText: !controller.isConfirmPasswordVisible.value,
                        onTogglePassword:
                            controller.toggleConfirmPasswordVisibility,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(context),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const PasswordRequirementsPanel(),
                    const SizedBox(height: 22),
                    Obx(
                      () => AuthPrimaryButton(
                        label: 'CADASTRAR AGORA',
                        isLoading: controller.isLoading.value,
                        onPressed: () => _submit(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: Get.back,
                      child: Text(
                        'Já possui uma conta? Faça Login',
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
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!controller.acceptedSensitiveDataConsent.value) {
      final accepted = await showAuthSensitiveDataConsentSheet(context);
      if (!accepted) return;
      controller.setSensitiveDataConsentAccepted(true);
    }
    await controller.register();
  }
}
