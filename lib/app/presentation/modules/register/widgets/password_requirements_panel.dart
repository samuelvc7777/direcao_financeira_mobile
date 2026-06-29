import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../register_controller.dart';

class PasswordRequirementsPanel extends GetView<RegisterController> {
  const PasswordRequirementsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F2A24) : const Color(0xFFEAF8F0),
        borderRadius: BorderRadius.circular(18),
        border: isDark ? Border.all(color: const Color(0xFF1F4D42)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requisitos da senha',
            style: TextStyle(
              color: isDark ? const Color(0xFFD1FAE5) : const Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _RequirementChip(
                  label: '8 caracteres',
                  isMet: controller.hasMinLength.value,
                ),
                _RequirementChip(
                  label: '1 maiúscula',
                  isMet: controller.hasUppercase.value,
                ),
                _RequirementChip(
                  label: '1 minúscula',
                  isMet: controller.hasLowercase.value,
                ),
                _RequirementChip(
                  label: '1 símbolo',
                  isMet: controller.hasSpecial.value,
                ),
                _RequirementChip(
                  label: 'senhas idênticas',
                  isMet: controller.passwordsMatch.value,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementChip extends StatelessWidget {
  const _RequirementChip({required this.label, required this.isMet});

  final String label;
  final bool isMet;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = const Color(0xFF10B981);

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162B27) : Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMet
                ? Icons.check_circle_outline_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 15,
            color: isMet ? activeColor : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
