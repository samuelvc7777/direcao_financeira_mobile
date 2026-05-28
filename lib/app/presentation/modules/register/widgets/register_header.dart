import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:direcao_financeira_mobile/app/core/theme/app_colors.dart';

class RegisterHeader extends StatelessWidget {
  const RegisterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface),
            onPressed: () => Get.back(),
          ),
        ),
        const Icon(Icons.person_add_rounded, size: 80, color: AppColors.teal),
        const SizedBox(height: 16),
        Text(
          'Criar Conta',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          'Junte-se à elite dos motoristas',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}
