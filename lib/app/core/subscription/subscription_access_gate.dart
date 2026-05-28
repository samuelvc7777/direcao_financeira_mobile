import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_pages.dart';
import '../session/user_cache.dart';
import '../theme/app_colors.dart';

class SubscriptionAccessGate {
  const SubscriptionAccessGate._();

  static bool get hasActivePlan {
    if (!Get.isRegistered<UserCache>()) {
      return false;
    }

    return Get.find<UserCache>().getUser()?.activeSubscription?.grantsAccess ??
        false;
  }

  static Future<bool> ensureAccess() async {
    if (hasActivePlan) {
      return true;
    }

    await showPremiumRequiredDialog();
    return false;
  }

  static Future<void> showPremiumRequiredDialog() async {
    if (Get.isDialogOpen == true || Get.context == null) {
      return;
    }

    await Get.dialog<void>(
      const _PremiumRequiredDialog(),
      barrierColor: Colors.black.withValues(alpha: 0.62),
    );
  }
}

class _PremiumRequiredDialog extends StatelessWidget {
  const _PremiumRequiredDialog();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: width < 380 ? 18 : 28,
        vertical: 24,
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.amber.withValues(alpha: 0.88),
              const Color(0xFF2B2111),
              colorScheme.surface,
            ],
          ),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.34)),
          boxShadow: [
            BoxShadow(
              color: AppColors.amber.withValues(alpha: 0.22),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.amber.withValues(alpha: 0.46),
                    ),
                  ),
                  child: const Text(
                    'PREMIUM',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'Assinatura premium',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                height: 1.05,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sua conta esta sem plano ativo. Ative sua assinatura premium para liberar o app com todas as funcionalidades.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            _PremiumBenefit(
              icon: Icons.lock_open_rounded,
              label: 'Libere os recursos premium do aplicativo',
            ),
            const SizedBox(height: 8),
            _PremiumBenefit(
              icon: Icons.shield_rounded,
              label: 'Mantenha sua experiencia ativa e protegida',
            ),
            const SizedBox(height: 8),
            _PremiumBenefit(
              icon: Icons.credit_card_rounded,
              label: 'Escolha um plano na tela de assinatura',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: () {
                  Get.back<void>();
                  Get.toNamed(AppRoutes.subscription);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text(
                  'VER ASSINATURA',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumBenefit extends StatelessWidget {
  const _PremiumBenefit({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.amber, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
