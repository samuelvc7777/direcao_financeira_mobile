import 'package:flutter/material.dart';
import 'package:direcao_financeira_mobile/app/core/theme/app_colors.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const Icon(
          Icons.directions_car_filled_rounded,
          size: 80,
          color: AppColors.teal,
        ),
        const SizedBox(height: 16),
        Text(
          'Direção Financeira',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          'Gestão de Elite para Motoristas',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}
