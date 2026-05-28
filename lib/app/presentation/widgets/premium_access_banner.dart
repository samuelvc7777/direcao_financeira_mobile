import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';

class PremiumAccessBanner extends StatelessWidget {
  const PremiumAccessBanner({super.key, required this.onViewSubscription});

  final VoidCallback onViewSubscription;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.38)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.34),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding == 0 ? 0 : 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _PremiumBadge(),
                            const SizedBox(height: 8),
                            Text(
                              'Assinatura premium',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sua conta precisa de um plano ativo vigente para usar esta funcionalidade.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.74),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _BenefitLine(text: 'Liberar recursos premium do app'),
                  const SizedBox(height: 8),
                  const _BenefitLine(text: 'Manter sua experiencia ativa'),
                  const SizedBox(height: 8),
                  const _BenefitLine(text: 'Escolher um plano de assinatura'),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onViewSubscription,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: const Color(0xFF111827),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text(
                      'VER ASSINATURA',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.30)),
        ),
        child: const Text(
          'PREMIUM',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _BenefitLine extends StatelessWidget {
  const _BenefitLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.gold,
            size: 15,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
