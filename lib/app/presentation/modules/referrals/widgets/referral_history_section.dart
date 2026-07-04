import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/referral_entity.dart';
import '../referrals_controller.dart';

class ReferralHistorySection extends StatelessWidget {
  const ReferralHistorySection({super.key, required this.controller});

  final ReferralsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Indicados'),
          const SizedBox(height: 10),
          if (controller.referrals.isEmpty)
            const _EmptyState(
              icon: Icons.group_add_rounded,
              title: 'Nenhum indicado ainda',
              message: 'Compartilhe seu codigo para comecar a acumular saldo.',
            )
          else
            ...controller.referrals.map(
              (referral) => _ReferralTile(
                referral: referral,
                statusLabel: controller.statusLabel(referral.status),
                amount: controller.formatMoney(referral.rewardCents),
              ),
            ),
          const SizedBox(height: 22),
          _SectionTitle(title: 'Saques Pix'),
          const SizedBox(height: 10),
          if (controller.withdrawals.isEmpty)
            const _EmptyState(
              icon: Icons.pix_rounded,
              title: 'Nenhum saque solicitado',
              message: 'Quando houver saldo aprovado, solicite o Pix por aqui.',
            )
          else
            ...controller.withdrawals.map(
              (withdrawal) => _WithdrawalTile(
                withdrawal: withdrawal,
                statusLabel: controller.statusLabel(withdrawal.status),
                amount: controller.formatMoney(withdrawal.amountCents),
              ),
            ),
        ],
      );
    });
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: context.theme.colorScheme.onSurface.withValues(alpha: 0.6),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ReferralTile extends StatelessWidget {
  const _ReferralTile({
    required this.referral,
    required this.statusLabel,
    required this.amount,
  });

  final ReferralEntity referral;
  final String statusLabel;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return _HistoryTile(
      icon: Icons.person_add_alt_1_rounded,
      title: referral.referredUserName,
      subtitle: referral.referredUserEmail,
      trailingTitle: amount,
      trailingSubtitle: statusLabel,
      color: _statusColor(referral.status),
    );
  }
}

class _WithdrawalTile extends StatelessWidget {
  const _WithdrawalTile({
    required this.withdrawal,
    required this.statusLabel,
    required this.amount,
  });

  final PixWithdrawalEntity withdrawal;
  final String statusLabel;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return _HistoryTile(
      icon: Icons.pix_rounded,
      title: amount,
      subtitle: withdrawal.pixKey,
      trailingTitle: statusLabel,
      trailingSubtitle: 'Saque',
      color: _statusColor(withdrawal.status),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailingTitle,
    required this.trailingSubtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailingTitle;
  final String trailingSubtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.62),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trailingTitle,
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                trailingSubtitle,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.56),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.electricCyan, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.62),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'approved':
    case 'paid':
      return AppColors.emerald;
    case 'rejected':
      return AppColors.rose;
    case 'requested':
    case 'processing':
      return AppColors.royalBlue;
    default:
      return AppColors.amber;
  }
}
