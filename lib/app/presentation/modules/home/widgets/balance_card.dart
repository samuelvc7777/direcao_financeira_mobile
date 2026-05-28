import 'package:direcao_financeira_mobile/app/core/theme/app_colors.dart';
import 'package:direcao_financeira_mobile/app/core/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../home_controller.dart';

class BalanceCard extends GetView<HomeController> {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Obx(() {
      final isVisible = controller.isBalanceVisible.value;
      final saldo = controller.saldoTotal;
      final entradas = controller.entradas;
      final saidas = controller.saidas;
      final isPositivo = controller.isSaldoPositivo;
      final colorScheme = context.theme.colorScheme;
      final isDark = context.theme.brightness == Brightness.dark;
      final primaryTextColor = isDark ? Colors.white : colorScheme.onSurface;
      final secondaryTextColor = isDark
          ? Colors.white.withValues(alpha: 0.82)
          : colorScheme.onSurface.withValues(alpha: 0.72);
      final subtleTextColor = isDark
          ? Colors.white.withValues(alpha: 0.62)
          : colorScheme.onSurface.withValues(alpha: 0.58);
      final dividerColor = colorScheme.onSurface.withValues(alpha: 0.10);

      return Container(
        margin: EdgeInsets.symmetric(vertical: Responsive.vp(context, 1)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 360;
            final cardPadding = Responsive.sp(context, isCompact ? 16 : 18);
            final amountFontSize = Responsive.sp(context, isCompact ? 25 : 28);

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Responsive.sp(context, 24)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [
                          Color(0xFF1F3654),
                          Color(0xFF162A45),
                          Color(0xFF122238),
                        ]
                      : [
                          Color.alphaBlend(
                            AppColors.royalBlue.withValues(alpha: 0.18),
                            colorScheme.surface,
                          ),
                          Color.alphaBlend(
                            AppColors.electricCyan.withValues(alpha: 0.10),
                            colorScheme.surface,
                          ),
                          colorScheme.surface,
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepNavy.withValues(alpha: 0.22),
                    blurRadius: Responsive.sp(context, 20),
                    offset: Offset(0, Responsive.sp(context, 8)),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -Responsive.sp(context, 36),
                    top: -Responsive.sp(context, 30),
                    child: Container(
                      width: Responsive.sp(context, 126),
                      height: Responsive.sp(context, 126),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryTextColor.withValues(alpha: isDark ? 0.04 : 0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    right: Responsive.sp(context, 44),
                    top: Responsive.sp(context, 52),
                    child: Container(
                      width: Responsive.sp(context, 12),
                      height: Responsive.sp(context, 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryTextColor.withValues(alpha: isDark ? 0.04 : 0.08),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: Responsive.sp(context, 30),
                              height: Responsive.sp(context, 30),
                              decoration: BoxDecoration(
                                color: primaryTextColor.withValues(alpha: isDark ? 0.09 : 0.08),
                                borderRadius: BorderRadius.circular(
                                  Responsive.sp(context, 10),
                                ),
                                border: Border.all(
                                  color: primaryTextColor.withValues(alpha: isDark ? 0.08 : 0.10),
                                ),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_rounded,
                                color: primaryTextColor,
                                size: Responsive.sp(context, 16),
                              ),
                            ),
                            SizedBox(width: Responsive.hp(context, 2.2)),
                            Expanded(
                              child: Text(
                                'Saldo Atual',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: Responsive.sp(context, 14),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: controller.toggleBalanceVisibility,
                                child: Ink(
                                  width: Responsive.sp(context, 32),
                                  height: Responsive.sp(context, 32),
                                  decoration: BoxDecoration(
                                    color: primaryTextColor.withValues(alpha: isDark ? 0.10 : 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isVisible
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    color: secondaryTextColor,
                                    size: Responsive.sp(context, 16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Responsive.vp(context, 1.7)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            isVisible
                                ? currencyFormat.format(saldo)
                                : 'R\$ ••••••',
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: amountFontSize,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              height: 1,
                            ),
                          ),
                        ),
                        SizedBox(height: Responsive.vp(context, 1.8)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.sp(context, 10),
                            vertical: Responsive.sp(context, 6),
                          ),
                          decoration: BoxDecoration(
                            color: isPositivo
                                ? AppColors.emerald.withValues(alpha: 0.20)
                                : AppColors.rose.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isPositivo
                                  ? AppColors.emerald.withValues(alpha: 0.20)
                                  : AppColors.rose.withValues(alpha: 0.20),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPositivo
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                color: isPositivo
                                    ? AppColors.emerald
                                    : AppColors.rose,
                                size: Responsive.sp(context, 14),
                              ),
                              SizedBox(width: Responsive.hp(context, 1)),
                              Text(
                                isPositivo ? 'Positivo' : 'Negativo',
                                style: TextStyle(
                                  color: isPositivo
                                      ? AppColors.emerald
                                      : AppColors.rose,
                                  fontSize: Responsive.sp(context, 12),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: Responsive.vp(context, 2.1)),
                        Container(
                          height: 1,
                          color: dividerColor,
                        ),
                        SizedBox(height: Responsive.vp(context, 1.8)),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoItem(
                                icon: Icons.arrow_upward_rounded,
                                label: 'Entradas',
                                value: entradas,
                                accent: AppColors.emerald,
                                isVisible: isVisible,
                                currencyFormat: currencyFormat,
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: subtleTextColor,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: Responsive.sp(context, 36),
                              margin: EdgeInsets.symmetric(
                                horizontal: Responsive.hp(context, 4),
                              ),
                              color: dividerColor,
                            ),
                            Expanded(
                              child: _InfoItem(
                                icon: Icons.arrow_downward_rounded,
                                label: 'Saidas',
                                value: saidas,
                                accent: AppColors.rose,
                                isVisible: isVisible,
                                currencyFormat: currencyFormat,
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: subtleTextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.isVisible,
    required this.currencyFormat,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  final IconData icon;
  final String label;
  final double value;
  final Color accent;
  final bool isVisible;
  final NumberFormat currencyFormat;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: Responsive.sp(context, 26),
          height: Responsive.sp(context, 26),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(Responsive.sp(context, 8)),
          ),
          child: Icon(icon, color: accent, size: Responsive.sp(context, 14)),
        ),
        SizedBox(width: Responsive.hp(context, 2)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: Responsive.sp(context, 11.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: Responsive.vp(context, 0.2)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  isVisible ? currencyFormat.format(value) : 'R\$ ••••',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: Responsive.sp(context, 16),
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
