import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../register_controller.dart';

class PasswordRequirementsPanel extends GetView<RegisterController> {
  const PasswordRequirementsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequirementItem(
            context,
            'Mínimo 8 caracteres',
            controller.hasMinLength.value,
          ),
          _buildRequirementItem(
            context,
            'Uma letra maiúscula',
            controller.hasUppercase.value,
          ),
          _buildRequirementItem(
            context,
            'Uma letra minúscula',
            controller.hasLowercase.value,
          ),
          _buildRequirementItem(
            context,
            'Um símbolo especial (@, #, \$...)',
            controller.hasSpecial.value,
          ),
          _buildRequirementItem(
            context,
            'As senhas são idênticas',
            controller.passwordsMatch.value,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(BuildContext context, String text, bool isMet) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: isMet
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.28),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.58),
              fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
