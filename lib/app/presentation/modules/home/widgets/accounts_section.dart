import 'package:direcao_financeira_mobile/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../domain/entities/bank_account_entity.dart';
import '../home_controller.dart';

class AccountsSection extends GetView<HomeController> {
  const AccountsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Obx(() {
      final contas = controller.contas;
      final saldoTotal = controller.saldoTotal;
      final isVisible = controller.isBalanceVisible.value;

      return LayoutBuilder(
        builder: (context, constraints) {
          final colorScheme = context.theme.colorScheme;
          final isDark = context.theme.brightness == Brightness.dark;
          final sectionPadding = Responsive.hp(context, 2.1).clamp(8.0, 10.0);
          final titleSize = Responsive.sp(context, 16).clamp(15.0, 16.0);
          final titleGap = Responsive.hp(context, 1.8).clamp(6.0, 8.0);
          final iconBoxSize = Responsive.hp(context, 7.4).clamp(28.0, 32.0);
          final arrowBoxSize = Responsive.hp(context, 6.4).clamp(24.0, 28.0);
          final sectionRadius = Responsive.hp(context, 4.8).clamp(16.0, 18.0);
          final contentGap = Responsive.vp(context, 1).clamp(6.0, 8.0);
          final listGap = Responsive.hp(context, 2.8).clamp(10.0, 12.0);
          final visibleCards = constraints.maxWidth >= 680 ? 3 : 2;
          final cardWidth =
              ((constraints.maxWidth -
                          (sectionPadding * 2) -
                          (listGap * (visibleCards - 1))) /
                      visibleCards)
                  .clamp(140.0, 160.0);
          final cardHeight = Responsive.vp(context, 17).clamp(132.0, 144.0);
          final totalLabelSize = Responsive.sp(context, 13).clamp(12.0, 13.0);
          final totalValueSize = Responsive.sp(context, 14).clamp(13.0, 14.0);

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: EdgeInsets.all(sectionPadding),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F222B) : colorScheme.surface,
              borderRadius: BorderRadius.circular(sectionRadius),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2F4367)
                    : colorScheme.onSurface.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () => Get.toNamed('/bank-accounts'),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 1,
                      vertical: 1,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: iconBoxSize,
                          height: iconBoxSize,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF244A77)
                                : AppColors.accountsAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            size: Responsive.sp(context, 16).clamp(15.0, 17.0),
                            color: isDark
                                ? const Color(0xFF8CC8FF)
                                : AppColors.accountsAccent,
                          ),
                        ),
                        SizedBox(width: titleGap),
                        Expanded(
                          child: Text(
                            'Minhas Contas',
                            style: TextStyle(
                              color: context.theme.colorScheme.onSurface,
                              fontSize: titleSize,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          width: arrowBoxSize,
                          height: arrowBoxSize,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF24364E)
                                : colorScheme.onSurface.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: Responsive.sp(context, 16).clamp(15.0, 17.0),
                            color: isDark
                                ? const Color(0xFF78AFFF)
                                : colorScheme.onSurface.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: contentGap),
                if (contas.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: Responsive.vp(context, 3).clamp(18.0, 24.0),
                    ),
                    child: Text(
                      'Nenhuma conta ativa',
                      style: TextStyle(
                        color: context.theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: Responsive.sp(context, 14).clamp(13.0, 14.0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: cardHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: contas.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(width: listGap),
                      itemBuilder: (context, index) {
                        final conta = contas[index];
                        return SizedBox(
                          width: cardWidth,
                          child: _AccountCard(
                            conta: conta,
                            isVisible: isVisible,
                            currencyFormat: currencyFormat,
                            color: _parseColor(conta.color),
                            icon: _getIconForType(conta.accountType),
                          ),
                        );
                      },
                    ),
                  ),
                SizedBox(height: contentGap),
                Container(
                  height: 1,
                  color: colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                SizedBox(height: contentGap),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Saldo Total',
                        style: TextStyle(
                          color: context.theme.colorScheme.onSurface.withValues(
                            alpha: 0.72,
                          ),
                          fontSize: totalLabelSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      isVisible
                          ? currencyFormat.format(saldoTotal)
                          : 'R\$ ....',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF6AAEFF)
                            : AppColors.accountsAccent,
                        fontSize: totalValueSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }

  IconData _getIconForType(AccountType type) {
    switch (type) {
      case AccountType.checking:
        return Icons.account_balance_rounded;
      case AccountType.savings:
        return Icons.savings_rounded;
      case AccountType.wallet:
        return Icons.account_balance_wallet_rounded;
      case AccountType.investment:
        return Icons.trending_up_rounded;
      case AccountType.other:
        return Icons.account_balance_wallet_outlined;
    }
  }

  Color _parseColor(String colorHex) {
    final normalized = colorHex.replaceFirst('#', '');
    if (normalized.length != 6) {
      return AppColors.electricCyan;
    }

    return Color(int.parse('FF$normalized', radix: 16));
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.conta,
    required this.isVisible,
    required this.currencyFormat,
    required this.color,
    required this.icon,
  });

  final BankAccountEntity conta;
  final bool isVisible;
  final NumberFormat currencyFormat;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cardPadding = Responsive.hp(context, 3.2).clamp(10.0, 12.0);
    final cardRadius = Responsive.hp(context, 4.3).clamp(14.0, 16.0);
    final iconBoxSize = Responsive.hp(context, 6.9).clamp(24.0, 26.0);
    final badgeHorizontal = Responsive.hp(context, 2.1).clamp(7.0, 8.0);
    final badgeVertical = Responsive.vp(context, 0.4).clamp(3.0, 4.0);
    final nameSize = Responsive.sp(context, 14).clamp(13.0, 14.0);
    final valueSize = Responsive.sp(context, 15).clamp(14.0, 15.0);

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: iconBoxSize,
                height: iconBoxSize,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: Responsive.sp(context, 15).clamp(14.0, 15.0),
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: badgeHorizontal,
                  vertical: badgeVertical,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  conta.accountType.label.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: Responsive.sp(context, 8).clamp(7.0, 8.0),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            conta.name,
            maxLines: 2,
            style: TextStyle(
              color: context.theme.colorScheme.onSurface.withValues(
                alpha: 0.86,
              ),
              fontSize: nameSize,
              fontWeight: FontWeight.w500,
              height: 1.15,
            ),
          ),
          SizedBox(height: Responsive.vp(context, 1).clamp(6.0, 8.0)),
          Text(
            isVisible
                ? currencyFormat.format(conta.currentBalance)
                : 'R\$ ....',
            style: TextStyle(
              color: context.theme.colorScheme.onSurface,
              fontSize: valueSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
