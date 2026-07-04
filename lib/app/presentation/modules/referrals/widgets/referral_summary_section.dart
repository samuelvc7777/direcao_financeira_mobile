import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../referrals_controller.dart';

class ReferralSummarySection extends StatelessWidget {
  const ReferralSummarySection({
    super.key,
    required this.controller,
    required this.onCopyCode,
    required this.onRequestWithdrawal,
  });

  final ReferralsController controller;
  final VoidCallback onCopyCode;
  final VoidCallback onRequestWithdrawal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Obx(() {
      final summary = controller.summary.value;
      final code = summary?.referralCode ?? '';
      final canRequestWithdrawal = controller.canRequestWithdrawal;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seu codigo',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.64),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        code.isEmpty ? 'Carregando...' : code,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: code.isEmpty ? null : onCopyCode,
                      icon: const Icon(Icons.copy_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: canRequestWithdrawal ? onRequestWithdrawal : null,
                  icon: const Icon(Icons.pix_rounded),
                  label: const Text('Solicitar saque'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Saque minimo: ${controller.minimumWithdrawalLabel}',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.62),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _BalanceTile(
                  label: 'Pendente',
                  value: controller.formatMoney(summary?.pendingCents ?? 0),
                  color: AppColors.amber,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BalanceTile(
                  label: 'Aprovado',
                  value: controller.formatMoney(summary?.approvedCents ?? 0),
                  color: AppColors.emerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _BalanceTile(
                  label: 'Pago',
                  value: controller.formatMoney(summary?.paidCents ?? 0),
                  color: AppColors.royalBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BalanceTile(
                  label: 'Indicados',
                  value: '${summary?.totalReferrals ?? 0}',
                  color: AppColors.violet,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.62),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
