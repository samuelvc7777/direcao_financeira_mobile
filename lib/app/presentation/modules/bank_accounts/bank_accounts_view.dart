import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/bank_account_entity.dart';
import '../../widgets/app_loading_indicator.dart';
import 'bank_accounts_controller.dart';
import 'widgets/bank_account_form_sheet.dart';

class BankAccountsView extends GetView<BankAccountsController> {
  const BankAccountsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingScreen(
            label: 'Carregando contas...',
            accentColor: AppColors.accountsAccent,
          );
        }

        final error = controller.errorMessage.value;
        if (error != null) {
          return _ErrorState(
            message: error,
            onRetry: controller.loadBankAccounts,
          );
        }

        return _BankAccountsBody(
          activeAccounts: controller.activeAccounts,
          inactiveAccounts: controller.inactiveAccounts,
          onCreatePressed: () => _showAccountForm(),
          onAccountPressed: (account) =>
              _showAccountForm(accountId: account.id),
          controller: controller,
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAccountForm(),
        backgroundColor: AppColors.accountsAccent,
        elevation: 8,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  void _showAccountForm({int? accountId}) {
    final account = accountId == null
        ? null
        : controller.bankAccounts.firstWhereOrNull(
            (item) => item.id == accountId,
          );

    Get.bottomSheet(
      BankAccountFormSheet(account: account, controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

// ─────────────────────────────────────────────────────────
// BODY PRINCIPAL
// ─────────────────────────────────────────────────────────

class _BankAccountsBody extends StatelessWidget {
  const _BankAccountsBody({
    required this.activeAccounts,
    required this.inactiveAccounts,
    required this.onCreatePressed,
    required this.onAccountPressed,
    required this.controller,
  });

  final List<BankAccountEntity> activeAccounts;
  final List<BankAccountEntity> inactiveAccounts;
  final VoidCallback onCreatePressed;
  final void Function(BankAccountEntity) onAccountPressed;
  final BankAccountsController controller;

  @override
  Widget build(BuildContext context) {
    if (activeAccounts.isEmpty && inactiveAccounts.isEmpty) {
      return _EmptyState(onCreatePressed: onCreatePressed);
    }

    final totalBalance = activeAccounts.fold<int>(
      0,
      (sum, a) => sum + a.currentBalanceCents,
    );

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // ── SliverAppBar com Hero ──
        _HeroSliverAppBar(
          totalBalance: totalBalance,
          activeCount: activeAccounts.length,
          inactiveCount: inactiveAccounts.length,
          controller: controller,
        ),

        // ── Contas Ativas ──
        if (activeAccounts.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: _SectionLabel(
                title: 'Contas Ativas',
                count: activeAccounts.length,
                color: AppColors.accountsAccent,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.builder(
              itemCount: activeAccounts.length,
              itemBuilder: (context, index) {
                final account = activeAccounts[index];
                return _AccountCard(
                  account: account,
                  controller: controller,
                  onTap: () => onAccountPressed(account),
                  index: index,
                );
              },
            ),
          ),
        ],

        // ── Contas Inativas ──
        if (inactiveAccounts.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: _SectionLabel(
                title: 'Pausadas',
                count: inactiveAccounts.length,
                color: Colors.grey,
                subtle: true,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.builder(
              itemCount: inactiveAccounts.length,
              itemBuilder: (context, index) {
                final account = inactiveAccounts[index];
                return Opacity(
                  opacity: 0.55,
                  child: _AccountCard(
                    account: account,
                    controller: controller,
                    onTap: () => onAccountPressed(account),
                    index: index,
                    isInactive: true,
                  ),
                );
              },
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// SLIVER APP BAR HERO
// ─────────────────────────────────────────────────────────

class _HeroSliverAppBar extends StatelessWidget {
  const _HeroSliverAppBar({
    required this.totalBalance,
    required this.activeCount,
    required this.inactiveCount,
    required this.controller,
  });

  final int totalBalance;
  final int activeCount;
  final int inactiveCount;
  final BankAccountsController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final onSurface = context.theme.colorScheme.onSurface;
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final isNegative = totalBalance < 0;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface),
        onPressed: () => Get.back(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.accountsAccent.withValues(alpha: 0.18),
                      context.theme.scaffoldBackgroundColor,
                    ]
                  : [
                      AppColors.accountsAccent.withValues(alpha: 0.10),
                      context.theme.scaffoldBackgroundColor,
                    ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Icone + Badge
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accountsAccent,
                              AppColors.accountsAccent.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accountsAccent.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Minhas Contas',
                            style: TextStyle(
                              color: onSurface,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Patrimônio consolidado',
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.5),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Valor total
                  Text(
                    formatter.format(totalBalance / 100.0),
                    style: TextStyle(
                      color: isNegative
                          ? AppColors.rose
                          : (isDark ? Colors.white : onSurface),
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saldo total disponível',
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.45),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pills
                  Row(
                    children: [
                      _StatusPill(
                        label: '$activeCount ativas',
                        color: AppColors.emerald,
                      ),
                      const SizedBox(width: 8),
                      if (inactiveCount > 0)
                        _StatusPill(
                          label: '$inactiveCount pausadas',
                          color: Colors.grey,
                        ),
                    ],
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

// ─────────────────────────────────────────────────────────
// CARD DE CONTA
// ─────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.controller,
    required this.onTap,
    required this.index,
    this.isInactive = false,
  });

  final BankAccountEntity account;
  final BankAccountsController controller;
  final VoidCallback onTap;
  final int index;
  final bool isInactive;

  IconData _iconForType(AccountType type) {
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
        return Icons.folder_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final onSurface = context.theme.colorScheme.onSurface;
    final accentColor = controller.colorFromHex(account.color);
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final isNegative = account.currentBalanceCents < 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isDark
                  ? onSurface.withValues(alpha: 0.04)
                  : context.theme.colorScheme.surface,
              border: Border.all(
                color: accentColor.withValues(alpha: isDark ? 0.25 : 0.12),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: isDark ? 0.08 : 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Icon + Nome + Tipo
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor,
                              accentColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _iconForType(account.accountType),
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              account.bankName,
                              style: TextStyle(
                                color: onSurface.withValues(alpha: 0.5),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          account.accountType.label,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Divider estilizado
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: 0.3),
                          accentColor.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Saldo atual
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saldo atual',
                              style: TextStyle(
                                color: onSurface.withValues(alpha: 0.45),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatter.format(account.currentBalance),
                              style: TextStyle(
                                color: isNegative ? AppColors.rose : onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Saldo inicial',
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.35),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatter.format(account.initialBalance),
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.55),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Indicador de variação
                  _BalanceVariationIndicator(
                    current: account.currentBalanceCents,
                    initial: account.initialBalanceCents,
                    accentColor: accentColor,
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

// ─────────────────────────────────────────────────────────
// INDICADOR DE VARIAÇÃO DE SALDO
// ─────────────────────────────────────────────────────────

class _BalanceVariationIndicator extends StatelessWidget {
  const _BalanceVariationIndicator({
    required this.current,
    required this.initial,
    required this.accentColor,
  });

  final int current;
  final int initial;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final diff = current - initial;
    final isPositive = diff >= 0;
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final color = isPositive ? AppColors.emerald : AppColors.rose;

    double percentage = 0;
    if (initial != 0) {
      percentage = (diff / initial.abs()) * 100;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(
            isPositive
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            '${isPositive ? '+' : ''}${formatter.format(diff / 100.0)}',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '${isPositive ? '+' : ''}${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    required this.count,
    required this.color,
    this.subtle = false,
  });

  final String title;
  final int count;
  final Color color;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.theme.colorScheme.onSurface;

    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            color: subtle ? onSurface.withValues(alpha: 0.12) : color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: onSurface.withValues(alpha: subtle ? 0.5 : 0.85),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// ESTADOS
// ─────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.theme.colorScheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.amber.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.amber,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Erro ao carregar',
              style: TextStyle(
                color: onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accountsAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreatePressed});

  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.theme.colorScheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.accountsAccent.withValues(alpha: 0.18),
                    AppColors.accountsAccent.withValues(alpha: 0.06),
                  ],
                ),
                border: Border.all(
                  color: AppColors.accountsAccent.withValues(alpha: 0.15),
                ),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.accountsAccent,
                size: 44,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Nenhuma conta cadastrada',
              style: TextStyle(
                color: onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Cadastre sua primeira conta e comece a acompanhar seu patrimônio.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.5),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onCreatePressed,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Cadastrar conta'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accountsAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
