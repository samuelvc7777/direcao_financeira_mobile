import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/bank_account_entity.dart';

class BankAccountsContent extends StatelessWidget {
  const BankAccountsContent({
    super.key,
    required this.activeAccounts,
    required this.inactiveAccounts,
    required this.onCreatePressed,
    required this.onAccountPressed,
  });

  final List<BankAccountEntity> activeAccounts;
  final List<BankAccountEntity> inactiveAccounts;
  final VoidCallback onCreatePressed;
  final ValueChanged<BankAccountEntity> onAccountPressed;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width < 380
        ? 16.0
        : width < 720
        ? 20.0
        : 28.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.theme.scaffoldBackgroundColor,
            Color.alphaBlend(
              AppColors.electricCyan.withValues(alpha: 0.04),
              context.theme.scaffoldBackgroundColor,
            ),
          ],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -90,
            right: -60,
            child: _AmbientGlow(size: 220, color: AppColors.electricCyan),
          ),
          Positioned(
            top: 240,
            left: -90,
            child: _AmbientGlow(
              size: 180,
              color: AppColors.sky.withValues(alpha: 0.55),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: ListView(
                physics: const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  18,
                  horizontalPadding,
                  120,
                ),
                children: [
                  _AccountsHero(
                    accounts: activeAccounts,
                    onCreatePressed: onCreatePressed,
                  ),
                  const SizedBox(height: 20),
                  _AccountsSnapshot(accounts: activeAccounts),
                  const SizedBox(height: 24),
                  _AccountsSection(
                    title: 'Contas em operacao',
                    subtitle:
                        'Visual mais analitico do seu dinheiro disponivel agora.',
                    accounts: activeAccounts,
                    emptyTitle: 'Nenhuma conta ativa por aqui',
                    emptyMessage:
                        'Crie sua primeira conta para montar o mapa do seu caixa.',
                    isInactiveSection: false,
                    onCreatePressed: onCreatePressed,
                    onAccountPressed: onAccountPressed,
                  ),
                  if (inactiveAccounts.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _AccountsSection(
                      title: 'Arquivo de contas',
                      subtitle:
                          'Itens pausados, preservados para historico e reativacao.',
                      accounts: inactiveAccounts,
                      emptyTitle: '',
                      emptyMessage: '',
                      isInactiveSection: true,
                      onCreatePressed: onCreatePressed,
                      onAccountPressed: onAccountPressed,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountsHero extends StatelessWidget {
  const _AccountsHero({required this.accounts, required this.onCreatePressed});

  final List<BankAccountEntity> accounts;
  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final total = accounts.fold<double>(
      0,
      (sum, item) => sum + item.currentBalance,
    );
    final initial = accounts.fold<double>(
      0,
      (sum, item) => sum + item.initialBalance,
    );
    final variation = total - initial;
    final positiveShare = accounts.isEmpty
        ? 0.0
        : accounts.where((item) => item.currentBalance >= 0).length /
              accounts.length;
    final widestCard = accounts.isEmpty
        ? null
        : accounts.reduce(
            (current, next) =>
                current.currentBalance >= next.currentBalance ? current : next,
          );
    final isWide = MediaQuery.of(context).size.width >= 760;
    final colorScheme = context.theme.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF041B28), Color(0xFF0A3040), Color(0xFF0C3F52)]
              : [
                  Color.alphaBlend(
                    AppColors.electricCyan.withValues(alpha: 0.16),
                    colorScheme.surface,
                  ),
                  Color.alphaBlend(
                    AppColors.sky.withValues(alpha: 0.10),
                    colorScheme.surface,
                  ),
                  colorScheme.surface,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.electricCyan.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isWide ? 28 : 22),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: _HeroMainColumn(
                      totalLabel: 'Caixa consolidado',
                      totalValue: currency.format(total),
                      description:
                          'Uma leitura mais forte e executiva das suas contas correntes, reservas e carteiras ativas.',
                      highlightLabel: widestCard?.name ?? 'Sem conta lider',
                      variationLabel: variation >= 0
                          ? 'Crescimento'
                          : 'Reducao',
                      variationValue: currency.format(variation),
                      positiveShare: positiveShare,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 5,
                    child: _HeroSidePanel(
                      initialBalance: currency.format(initial),
                      accountCount: accounts.length,
                      dominantType: _dominantTypeLabel(accounts),
                      onCreatePressed: onCreatePressed,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroMainColumn(
                    totalLabel: 'Caixa consolidado',
                    totalValue: currency.format(total),
                    description:
                        'Uma leitura mais forte e executiva das suas contas correntes, reservas e carteiras ativas.',
                    highlightLabel: widestCard?.name ?? 'Sem conta lider',
                    variationLabel: variation >= 0 ? 'Crescimento' : 'Reducao',
                    variationValue: currency.format(variation),
                    positiveShare: positiveShare,
                  ),
                  const SizedBox(height: 18),
                  _HeroSidePanel(
                    initialBalance: currency.format(initial),
                    accountCount: accounts.length,
                    dominantType: _dominantTypeLabel(accounts),
                    onCreatePressed: onCreatePressed,
                  ),
                ],
              ),
      ),
    );
  }

  String _dominantTypeLabel(List<BankAccountEntity> accounts) {
    if (accounts.isEmpty) return 'Sem perfil dominante';

    final counts = <AccountType, int>{};
    for (final account in accounts) {
      counts.update(
        account.accountType,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final dominant = counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    return dominant.label;
  }
}

class _HeroMainColumn extends StatelessWidget {
  const _HeroMainColumn({
    required this.totalLabel,
    required this.totalValue,
    required this.description,
    required this.highlightLabel,
    required this.variationLabel,
    required this.variationValue,
    required this.positiveShare,
  });

  final String totalLabel;
  final String totalValue;
  final String description;
  final String highlightLabel;
  final String variationLabel;
  final String variationValue;
  final double positiveShare;

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? Colors.white
        : context.theme.colorScheme.onSurface;
    final secondaryTextColor = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : context.theme.colorScheme.onSurface.withValues(alpha: 0.72);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _HeroTag(icon: Icons.blur_on_rounded, label: 'Visao premium'),
            _HeroTag(icon: Icons.tune_rounded, label: highlightLabel),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          totalLabel,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          totalValue,
          style: TextStyle(
            color: primaryTextColor,
            fontSize: MediaQuery.of(context).size.width >= 600 ? 42 : 36,
            fontWeight: FontWeight.w900,
            height: 0.95,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          description,
          style: TextStyle(
            color: secondaryTextColor,
            height: 1.55,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _HeroCallout(
                title: variationLabel,
                value: variationValue,
                tone: AppColors.sky,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HeroCallout(
                title: 'Contas positivas',
                value: '${(positiveShare * 100).round()}%',
                tone: AppColors.emerald,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroSidePanel extends StatelessWidget {
  const _HeroSidePanel({
    required this.initialBalance,
    required this.accountCount,
    required this.dominantType,
    required this.onCreatePressed,
  });

  final String initialBalance;
  final int accountCount;
  final String dominantType;
  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final colorScheme = context.theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Painel tatico',
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.72)
                  : colorScheme.onSurface.withValues(alpha: 0.68),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          _SideMetric(
            label: 'Saldo inicial',
            value: initialBalance,
            icon: Icons.flag_rounded,
          ),
          const SizedBox(height: 14),
          _SideMetric(
            label: 'Estruturas ativas',
            value: '$accountCount',
            icon: Icons.account_tree_rounded,
          ),
          const SizedBox(height: 14),
          _SideMetric(
            label: 'Perfil dominante',
            value: dominantType,
            icon: Icons.layers_rounded,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCreatePressed,
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? Colors.white
                    : colorScheme.primary,
                foregroundColor: isDark
                    ? const Color(0xFF072A39)
                    : colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Criar conta',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountsSnapshot extends StatelessWidget {
  const _AccountsSnapshot({required this.accounts});

  final List<BankAccountEntity> accounts;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final total = accounts.fold<double>(
      0,
      (sum, item) => sum + item.currentBalance,
    );
    final wallets = accounts
        .where((item) => item.accountType == AccountType.wallet)
        .length;
    final negativeCount = accounts
        .where((item) => item.currentBalance < 0)
        .length;
    final reserves = accounts
        .where((item) => item.accountType == AccountType.savings)
        .length;

    final items = [
      _SnapshotCardData(
        title: 'Liquidez imediata',
        value: currency.format(total),
        subtitle: 'Soma de todo o saldo ativo',
        icon: Icons.waterfall_chart_rounded,
        color: AppColors.electricCyan,
      ),
      _SnapshotCardData(
        title: 'Carteiras',
        value: '$wallets',
        subtitle: 'Caixa fisico e valores avulsos',
        icon: Icons.wallet_rounded,
        color: AppColors.amber,
      ),
      _SnapshotCardData(
        title: 'Reservas',
        value: '$reserves',
        subtitle: 'Contas com perfil de poupanca',
        icon: Icons.shield_moon_rounded,
        color: AppColors.royalBlue,
      ),
      _SnapshotCardData(
        title: 'Em alerta',
        value: '$negativeCount',
        subtitle: 'Contas com saldo abaixo de zero',
        icon: Icons.warning_amber_rounded,
        color: AppColors.rose,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 920
            ? 4
            : constraints.maxWidth >= 580
            ? 2
            : 1;
        final spacing = 14.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: _SnapshotCard(data: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _AccountsSection extends StatelessWidget {
  const _AccountsSection({
    required this.title,
    required this.subtitle,
    required this.accounts,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.isInactiveSection,
    required this.onCreatePressed,
    required this.onAccountPressed,
  });

  final String title;
  final String subtitle;
  final List<BankAccountEntity> accounts;
  final String emptyTitle;
  final String emptyMessage;
  final bool isInactiveSection;
  final VoidCallback onCreatePressed;
  final ValueChanged<BankAccountEntity> onAccountPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: context.theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: title,
            subtitle: subtitle,
            icon: isInactiveSection
                ? Icons.archive_rounded
                : Icons.account_balance_wallet_rounded,
            accentColor: isInactiveSection
                ? AppColors.textSecondary
                : AppColors.electricCyan,
          ),
          const SizedBox(height: 18),
          if (accounts.isEmpty)
            _AccountsEmpty(
              title: emptyTitle,
              message: emptyMessage,
              onCreatePressed: onCreatePressed,
            )
          else ...[
            _CashDistribution(accounts: accounts),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 620 ? 2 : 1;
                final spacing = 16.0;
                final cardWidth =
                    (constraints.maxWidth - (spacing * (columns - 1))) /
                    columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: accounts
                      .map(
                        (account) => SizedBox(
                          width: cardWidth,
                          child: _AccountSpotlightCard(
                            account: account,
                            isInactive: isInactiveSection,
                            onTap: () => onAccountPressed(account),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _CashDistribution extends StatelessWidget {
  const _CashDistribution({required this.accounts});

  final List<BankAccountEntity> accounts;

  @override
  Widget build(BuildContext context) {
    final positiveAccounts =
        accounts.where((item) => item.currentBalance > 0).toList()
          ..sort((a, b) => b.currentBalance.compareTo(a.currentBalance));
    final base = positiveAccounts.fold<double>(
      0,
      (sum, item) => sum + item.currentBalance,
    );
    final visibleItems = positiveAccounts.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: context.theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribuicao do caixa',
            style: TextStyle(
              color: context.theme.colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'As maiores posicoes aparecem primeiro para facilitar leitura rapida.',
            style: TextStyle(
              color: context.theme.colorScheme.onSurface.withValues(
                alpha: 0.56,
              ),
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          if (visibleItems.isEmpty)
            Text(
              'Sem valores positivos para distribuir.',
              style: TextStyle(
                color: context.theme.colorScheme.onSurface.withValues(
                  alpha: 0.56,
                ),
              ),
            )
          else
            Column(
              children: visibleItems.map((account) {
                final share = base <= 0 ? 0.0 : account.currentBalance / base;
                final color = _parseColor(
                  account.color,
                  AppColors.electricCyan,
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 104,
                        child: Text(
                          account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.theme.colorScheme.onSurface
                                .withValues(alpha: 0.72),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: share.clamp(0.0, 1.0),
                            backgroundColor: color.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(share * 100).round()}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _AccountSpotlightCard extends StatelessWidget {
  const _AccountSpotlightCard({
    required this.account,
    required this.isInactive,
    required this.onTap,
  });

  final BankAccountEntity account;
  final bool isInactive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final accent = _parseColor(account.color, AppColors.electricCyan);
    final delta = account.currentBalance - account.initialBalance;
    final isPositive = account.currentBalance >= 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isInactive
                ? [
                    accent.withValues(alpha: 0.08),
                    context.theme.colorScheme.surface,
                  ]
                : [
                    Color.alphaBlend(
                      accent.withValues(alpha: 0.16),
                      Colors.white,
                    ),
                    Color.alphaBlend(
                      accent.withValues(alpha: 0.05),
                      context.theme.colorScheme.surface,
                    ),
                  ],
          ),
          border: Border.all(
            color: accent.withValues(alpha: isInactive ? 0.16 : 0.28),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      _iconForType(account.accountType),
                      color: accent,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isInactive
                          ? 'ARQUIVADA'
                          : account.accountType.label.toUpperCase(),
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                account.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                account.bankName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.theme.colorScheme.onSurface.withValues(
                    alpha: 0.56,
                  ),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Saldo atual',
                style: TextStyle(
                  color: context.theme.colorScheme.onSurface.withValues(
                    alpha: 0.48,
                  ),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                currency.format(account.currentBalance),
                style: TextStyle(
                  color: isPositive
                      ? context.theme.colorScheme.onSurface
                      : AppColors.rose,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MiniInfo(
                      label: 'Inicial',
                      value: currency.format(account.initialBalance),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniInfo(
                      label: delta >= 0 ? 'Evolucao' : 'Reducao',
                      value: currency.format(delta),
                      valueColor: delta >= 0
                          ? AppColors.emerald
                          : AppColors.rose,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountsEmpty extends StatelessWidget {
  const _AccountsEmpty({
    required this.title,
    required this.message,
    required this.onCreatePressed,
  });

  final String title;
  final String message;
  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.electricCyan.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 44,
            color: AppColors.electricCyan,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.theme.colorScheme.onSurface.withValues(
                alpha: 0.58,
              ),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onCreatePressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.electricCyan,
              side: BorderSide(
                color: AppColors.electricCyan.withValues(alpha: 0.34),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Criar primeira conta',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: accentColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: context.theme.colorScheme.onSurface.withValues(
                    alpha: 0.56,
                  ),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({required this.data});

  final _SnapshotCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: data.color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(height: 16),
          Text(
            data.title,
            style: TextStyle(
              color: context.theme.colorScheme.onSurface.withValues(
                alpha: 0.56,
              ),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.theme.colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.subtitle,
            style: TextStyle(
              color: context.theme.colorScheme.onSurface.withValues(
                alpha: 0.54,
              ),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotCardData {
  const _SnapshotCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final foreground = isDark
        ? Colors.white
        : context.theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: foreground.withValues(alpha: isDark ? 0.12 : 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCallout extends StatelessWidget {
  const _HeroCallout({
    required this.title,
    required this.value,
    required this.tone,
  });

  final String title;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final colorScheme = context.theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.66)
                  : colorScheme.onSurface.withValues(alpha: 0.62),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tone,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SideMetric extends StatelessWidget {
  const _SideMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final colorScheme = context.theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : colorScheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: isDark ? Colors.white : colorScheme.onSurface,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              label,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.64)
                    : colorScheme.onSurface.withValues(alpha: 0.60),
                fontSize: 12,
              ),
            ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white : colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.theme.colorScheme.onSurface.withValues(
                alpha: 0.48,
              ),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? context.theme.colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

IconData _iconForType(AccountType type) {
  switch (type) {
    case AccountType.checking:
      return Icons.account_balance_rounded;
    case AccountType.savings:
      return Icons.savings_rounded;
    case AccountType.wallet:
      return Icons.wallet_rounded;
    case AccountType.investment:
      return Icons.show_chart_rounded;
    case AccountType.other:
      return Icons.layers_clear_rounded;
  }
}

Color _parseColor(String colorHex, Color fallback) {
  final normalized = colorHex.replaceFirst('#', '');
  if (normalized.length != 6) {
    return fallback;
  }

  return Color(int.parse('FF$normalized', radix: 16));
}
