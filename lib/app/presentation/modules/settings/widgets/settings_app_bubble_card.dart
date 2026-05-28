import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../settings_controller.dart';

class SettingsAppBubbleCard extends StatelessWidget {
  const SettingsAppBubbleCard({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BALÃO FLUTUANTE',
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Obx(() {
          final isEnabled = controller.isAppBubbleEnabled.value;
          final hasPermission = controller.isAppBubblePermissionGranted.value;
          final isBusy = controller.isAppBubbleBusy.value;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.violet.withValues(alpha: 0.96),
                            AppColors.royalBlue.withValues(alpha: 0.90),
                          ],
                        ),
                        border: Border.all(
                          color: colorScheme.onPrimary.withValues(alpha: 0.24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.violet.withValues(alpha: 0.20),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.bubble_chart_rounded,
                          color: colorScheme.onPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exibir logo sobre outros apps',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEnabled
                                ? 'Balão ativo fora do app. Toque nele para voltar rapidamente.'
                                : 'Mostra a logo da Direção Financeira em qualquer tela do celular.',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.62,
                              ),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isEnabled,
                      onChanged: isBusy ? null : controller.toggleAppBubble,
                      activeThumbColor: AppColors.aqua,
                      activeTrackColor: AppColors.royalBlue.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      label: hasPermission
                          ? 'Permissão liberada'
                          : 'Permissão pendente',
                      color: hasPermission
                          ? AppColors.emerald
                          : AppColors.amber,
                    ),
                    _StatusChip(
                      label: isEnabled ? 'Balão ligado' : 'Balão desligado',
                      color: isEnabled ? AppColors.royalBlue : AppColors.rose,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Você pode arrastar o balão pela tela e tocar nele para abrir o app.',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.54),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                if (!hasPermission) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: isBusy
                        ? null
                        : controller.openAppBubblePermissionSettings,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Liberar permissão'),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
