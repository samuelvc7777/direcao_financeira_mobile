import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/credit_card_entity.dart';

class CreditCardsContent extends StatelessWidget {
  const CreditCardsContent({
    super.key,
    required this.activeCards,
    required this.inactiveCards,
    required this.onCreatePressed,
    required this.onCardPressed,
  });

  final List<CreditCardEntity> activeCards;
  final List<CreditCardEntity> inactiveCards;
  final VoidCallback onCreatePressed;
  final ValueChanged<CreditCardEntity> onCardPressed;

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
              AppColors.violet.withValues(alpha: 0.04),
              context.theme.scaffoldBackgroundColor,
            ),
          ],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -110,
            left: -50,
            child: _AmbientGlow(size: 240, color: AppColors.violet),
          ),
          const Positioned(
            top: 260,
            right: -70,
            child: _AmbientGlow(size: 220, color: AppColors.rose),
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
                  _CardsHero(
                    cards: activeCards,
                    onCreatePressed: onCreatePressed,
                  ),
                  const SizedBox(height: 20),
                  _UsageOverview(cards: activeCards),
                  const SizedBox(height: 24),
                  _CardsSection(
                    title: 'Carteira principal',
                    subtitle:
                        'Cartoes ativos com leitura imediata de limite, gasto e fechamento.',
                    cards: activeCards,
                    isInactiveSection: false,
                    onCreatePressed: onCreatePressed,
                    onCardPressed: onCardPressed,
                  ),
                  if (inactiveCards.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _CardsSection(
                      title: 'Cartoes arquivados',
                      subtitle:
                          'Historico preservado para reativacao e consulta.',
                      cards: inactiveCards,
                      isInactiveSection: true,
                      onCreatePressed: onCreatePressed,
                      onCardPressed: onCardPressed,
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

class _CardsHero extends StatelessWidget {
  const _CardsHero({required this.cards, required this.onCreatePressed});

  final List<CreditCardEntity> cards;
  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final totalLimit = cards.fold<double>(0, (sum, item) => sum + item.limit);
    final totalCommitted = cards.fold<double>(
      0,
      (sum, item) => sum + item.usedLimit,
    );
    final totalOpenInvoices = cards.fold<double>(
      0,
      (sum, item) => sum + item.openInvoice,
    );
    final totalClosedInvoices = cards.fold<double>(
      0,
      (sum, item) => sum + item.closedInvoice,
    );
    final totalAvailable = totalLimit - totalCommitted;
    final averageUsage = cards.isEmpty
        ? 0.0
        : cards.fold<double>(0, (sum, item) => sum + item.usedPercentage) /
              cards.length;
    final headlineCard = cards.isEmpty
        ? null
        : cards.reduce(
            (a, b) => a.payableInvoiceCents >= b.payableInvoiceCents ? a : b,
          );
    final openCount = cards.where((card) => card.hasOpenInvoice).length;
    final closedCount = cards.where((card) => card.hasClosedInvoice).length;
    final dueCount = cards.where((card) => card.canPayInvoice).length;
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
              ? const [Color(0xFF1F1237), Color(0xFF341A57), Color(0xFF4A1B5E)]
              : [
                  Color.alphaBlend(
                    AppColors.violet.withValues(alpha: 0.16),
                    colorScheme.surface,
                  ),
                  Color.alphaBlend(
                    AppColors.amber.withValues(alpha: 0.08),
                    colorScheme.surface,
                  ),
                  colorScheme.surface,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.22),
            blurRadius: 34,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isWide ? 28 : 22),
        child: isWide
            ? Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: _HeroMainPanel(
                      available: currency.format(totalAvailable),
                      committed: currency.format(totalCommitted),
                      openInvoices: currency.format(totalOpenInvoices),
                      closedInvoices: currency.format(totalClosedInvoices),
                      averageUsage: '${(averageUsage * 100).round()}%',
                      spotlight: headlineCard == null
                          ? 'Sem cartao em destaque'
                          : headlineCard.canPayInvoice
                          ? '${headlineCard.name} pede pagamento'
                          : '${headlineCard.name} lidera o uso',
                      openCount: openCount,
                      closedCount: closedCount,
                      dueCount: dueCount,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 5,
                    child: _HeroCardPreview(
                      card: headlineCard,
                      totalLimit: currency.format(totalLimit),
                      onCreatePressed: onCreatePressed,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _HeroMainPanel(
                    available: currency.format(totalAvailable),
                    committed: currency.format(totalCommitted),
                    openInvoices: currency.format(totalOpenInvoices),
                    closedInvoices: currency.format(totalClosedInvoices),
                    averageUsage: '${(averageUsage * 100).round()}%',
                    spotlight: headlineCard == null
                        ? 'Sem cartao em destaque'
                        : headlineCard.canPayInvoice
                        ? '${headlineCard.name} pede pagamento'
                        : '${headlineCard.name} lidera o uso',
                    openCount: openCount,
                    closedCount: closedCount,
                    dueCount: dueCount,
                  ),
                  const SizedBox(height: 18),
                  _HeroCardPreview(
                    card: headlineCard,
                    totalLimit: currency.format(totalLimit),
                    onCreatePressed: onCreatePressed,
                  ),
                ],
              ),
      ),
    );
  }
}

class _HeroMainPanel extends StatelessWidget {
  const _HeroMainPanel({
    required this.available,
    required this.committed,
    required this.openInvoices,
    required this.closedInvoices,
    required this.averageUsage,
    required this.spotlight,
    required this.openCount,
    required this.closedCount,
    required this.dueCount,
  });

  final String available;
  final String committed;
  final String openInvoices;
  final String closedInvoices;
  final String averageUsage;
  final String spotlight;
  final int openCount;
  final int closedCount;
  final int dueCount;

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
            _HeroChip(icon: Icons.diamond_outlined, label: 'Modo premium'),
            _HeroChip(
              icon: Icons.local_fire_department_rounded,
              label: spotlight,
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'Disponivel para usar',
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text('', style: TextStyle(fontSize: 0)),
        Text(
          available,
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 38,
            fontWeight: FontWeight.w900,
            height: 0.95,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Um painel mais ousado para enxergar limite, compromissos e ritmo de uso da sua carteira.',
          style: TextStyle(
            color: secondaryTextColor,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _HeroStat(
                label: 'Faturas abertas',
                value: openInvoices,
                color: AppColors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HeroStat(
                label: 'Faturas fechadas',
                value: closedInvoices,
                color: AppColors.rose,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _HeroChip(
              icon: Icons.account_balance_wallet_rounded,
              label: '$openCount abertas',
            ),
            _HeroChip(
              icon: Icons.receipt_long_rounded,
              label: '$closedCount fechadas',
            ),
            _HeroChip(
              icon: Icons.payments_rounded,
              label: '$dueCount para pagar',
            ),
            _HeroChip(
              icon: Icons.pie_chart_rounded,
              label: 'Uso medio $averageUsage',
            ),
            _HeroChip(
              icon: Icons.credit_score_rounded,
              label: 'Comprometido $committed',
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroCardPreview extends StatelessWidget {
  const _HeroCardPreview({
    required this.card,
    required this.totalLimit,
    required this.onCreatePressed,
  });

  final CreditCardEntity? card;
  final String totalLimit;
  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    final accent = _parseColor(card?.color, AppColors.violet);
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
            'Cartao em foco',
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.72)
                  : colorScheme.onSurface.withValues(alpha: 0.68),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    Colors.white.withValues(alpha: 0.16),
                    accent,
                  ),
                  accent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.credit_card_rounded, color: Colors.white),
                    const Spacer(),
                    Text(
                      (card?.brand ?? 'Carteira').toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  card?.name ?? 'Nenhum cartao ativo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  card == null
                      ? 'Cadastre um cartao para ativar a leitura.'
                      : 'Fechamento ${card!.closingDay} | Vence ${card!.dueDay}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _InlineMetric(label: 'Limite total da carteira', value: totalLimit),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCreatePressed,
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? Colors.white
                    : colorScheme.primary,
                foregroundColor: isDark
                    ? const Color(0xFF28153C)
                    : colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.add_card_rounded),
              label: const Text(
                'Adicionar cartao',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageOverview extends StatelessWidget {
  const _UsageOverview({required this.cards});

  final List<CreditCardEntity> cards;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final highestLimit = cards.isEmpty
        ? 0.0
        : cards.map((item) => item.limit).reduce((a, b) => a > b ? a : b);
    final mostFree = cards.isEmpty
        ? 0.0
        : cards
              .map((item) => item.availableLimit)
              .reduce((a, b) => a > b ? a : b);
    final nextDueCard = cards
        .where((card) => card.nextDueDate != null)
        .fold<CreditCardEntity?>(
          null,
          (current, card) =>
              current == null ||
                  card.nextDueDate!.isBefore(current.nextDueDate!)
              ? card
              : current,
        );
    final openInvoicesCount = cards.where((card) => card.hasOpenInvoice).length;
    final closedInvoicesCount = cards
        .where((card) => card.hasClosedInvoice)
        .length;
    final dueTodayOrOverdueCount = cards
        .where((card) => card.canPayInvoice)
        .length;

    final nextOpenClosingCard = cards
        .where((card) => card.openInvoiceClosingDate != null)
        .fold<CreditCardEntity?>(
          null,
          (current, card) =>
              current == null ||
                  card.openInvoiceClosingDate!.isBefore(
                    current.openInvoiceClosingDate!,
                  )
              ? card
              : current,
        );

    final items = [
      _OverviewCardData(
        title: 'Maior limite',
        value: currency.format(highestLimit),
        subtitle: 'Seu teto individual mais alto',
        icon: Icons.auto_graph_rounded,
        color: AppColors.sky,
      ),
      _OverviewCardData(
        title: 'Maior folga',
        value: currency.format(mostFree),
        subtitle: 'Cartao com mais saldo ainda livre',
        icon: Icons.bolt_rounded,
        color: AppColors.emerald,
      ),
      _OverviewCardData(
        title: 'Proximo vencimento',
        value: nextDueCard == null
            ? '-'
            : DateFormat('dd/MM').format(nextDueCard.nextDueDate!),
        subtitle: nextDueCard?.name ?? 'Sem cartoes ativos',
        icon: Icons.event_available_rounded,
        color: AppColors.amber,
      ),
      _OverviewCardData(
        title: 'Faturas abertas',
        value: '$openInvoicesCount',
        subtitle: nextOpenClosingCard == null
            ? 'Nenhum ciclo aberto'
            : 'Proximo fechamento: ${nextOpenClosingCard.name}',
        icon: Icons.timelapse_rounded,
        color: AppColors.violet,
      ),
      _OverviewCardData(
        title: 'Faturas fechadas',
        value: '$closedInvoicesCount',
        subtitle: dueTodayOrOverdueCount == 0
            ? 'Nenhuma pronta para pagar'
            : '$dueTodayOrOverdueCount prontas para pagamento',
        icon: Icons.receipt_long_rounded,
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
                    child: _OverviewCard(data: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _CardsSection extends StatelessWidget {
  const _CardsSection({
    required this.title,
    required this.subtitle,
    required this.cards,
    required this.isInactiveSection,
    required this.onCreatePressed,
    required this.onCardPressed,
  });

  final String title;
  final String subtitle;
  final List<CreditCardEntity> cards;
  final bool isInactiveSection;
  final VoidCallback onCreatePressed;
  final ValueChanged<CreditCardEntity> onCardPressed;

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
            accentColor: isInactiveSection
                ? AppColors.textSecondary
                : AppColors.violet,
            icon: isInactiveSection
                ? Icons.archive_rounded
                : Icons.credit_card_rounded,
          ),
          const SizedBox(height: 18),
          if (cards.isEmpty)
            _CardsEmpty(onCreatePressed: onCreatePressed)
          else ...[
            _UsageLane(cards: cards),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 620 ? 2 : 1;
                final spacing = 16.0;
                final itemWidth =
                    (constraints.maxWidth - (spacing * (columns - 1))) /
                    columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: cards
                      .map(
                        (card) => SizedBox(
                          width: itemWidth,
                          child: _CreditCardSpotlight(
                            card: card,
                            isInactive: isInactiveSection,
                            onTap: () => onCardPressed(card),
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

class _UsageLane extends StatelessWidget {
  const _UsageLane({required this.cards});

  final List<CreditCardEntity> cards;

  @override
  Widget build(BuildContext context) {
    final ordered = [...cards]
      ..sort((a, b) => b.usedPercentage.compareTo(a.usedPercentage));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Escala de uso',
            style: TextStyle(
              color: context.theme.colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Os cartoes mais pressionados aparecem primeiro.',
            style: TextStyle(
              color: context.theme.colorScheme.onSurface.withValues(
                alpha: 0.56,
              ),
              height: 1.45,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: ordered.take(4).map((card) {
              final accent = _parseColor(card.color, AppColors.violet);

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 112,
                      child: Text(
                        card.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.theme.colorScheme.onSurface.withValues(
                            alpha: 0.72,
                          ),
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
                          value: card.usedPercentage.clamp(0.0, 1.0),
                          backgroundColor: accent.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            card.usedPercentage >= 0.85
                                ? AppColors.rose
                                : accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(card.usedPercentage * 100).round()}%',
                      style: TextStyle(
                        color: card.usedPercentage >= 0.85
                            ? AppColors.rose
                            : accent,
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

class _CreditCardSpotlight extends StatelessWidget {
  const _CreditCardSpotlight({
    required this.card,
    required this.isInactive,
    required this.onTap,
  });

  final CreditCardEntity card;
  final bool isInactive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final accent = _parseColor(card.color, AppColors.violet);
    final primaryInvoiceLabel = card.closedInvoiceCents > 0
        ? 'Fatura fechada'
        : card.openInvoiceCents > 0
        ? 'Fatura aberta'
        : 'Sem fatura pendente';
    final primaryInvoiceValue = card.closedInvoiceCents > 0
        ? card.closedInvoice
        : card.openInvoice;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
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
                      accent.withValues(alpha: 0.18),
                      Colors.white,
                    ),
                    Color.alphaBlend(
                      AppColors.rose.withValues(alpha: 0.06),
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
                      borderRadius: BorderRadius.circular(18),
                      color: accent.withValues(alpha: 0.14),
                    ),
                    child: Icon(Icons.credit_card_rounded, color: accent),
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
                      isInactive ? 'ARQUIVADO' : card.brand.toUpperCase(),
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
                card.name,
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
                'Fecha ${card.closingDay}  |  Vence ${card.dueDay}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.theme.colorScheme.onSurface.withValues(
                    alpha: 0.56,
                  ),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _MiniBlock(
                      label: 'Disponivel',
                      value: currency.format(card.availableLimit),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniBlock(
                      label: primaryInvoiceLabel,
                      value: currency.format(primaryInvoiceValue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _StatusBadge(
                    label: _buildClosingLabel(card),
                    color: accent,
                  ),
                  _StatusBadge(
                    label: _buildDueLabel(card),
                    color: card.isInvoiceOverdue
                        ? AppColors.rose
                        : card.isInvoiceDueToday
                        ? AppColors.amber
                        : accent,
                  ),
                  if (card.openInvoiceCents > 0)
                    _StatusBadge(
                      label:
                          'Aberta ${currency.format(card.openInvoice)}',
                      color: AppColors.amber,
                    ),
                  if (card.closedInvoiceCents > 0)
                    _StatusBadge(
                      label:
                          'Fechada ${currency.format(card.closedInvoice)}',
                      color: AppColors.rose,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Comprometimento do limite',
                style: TextStyle(
                  color: context.theme.colorScheme.onSurface.withValues(
                    alpha: 0.48,
                  ),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 9,
                  value: card.usedPercentage.clamp(0.0, 1.0),
                  backgroundColor: accent.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    card.usedPercentage >= 0.9 ? AppColors.rose : accent,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currency.format(card.usedLimit),
                    style: TextStyle(
                      color: context.theme.colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${(card.usedPercentage * 100).round()}% utilizado',
                    style: TextStyle(
                      color: card.usedPercentage >= 0.9
                          ? AppColors.rose
                          : accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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

  String _buildClosingLabel(CreditCardEntity card) {
    if (card.openInvoiceClosingDate != null) {
      return 'Fecha ${DateFormat('dd/MM').format(card.openInvoiceClosingDate!)}';
    }

    return 'Fecha dia ${card.closingDay}';
  }

  String _buildDueLabel(CreditCardEntity card) {
    if (card.isInvoiceOverdue) {
      if (card.nextDueDate == null) {
        return 'Fatura em atraso';
      }
      return 'Atrasou ${DateFormat('dd/MM').format(card.nextDueDate!)}';
    }
    if (card.isInvoiceDueToday) {
      return 'Vence hoje';
    }
    if (card.nextDueDate != null) {
      return 'Vence ${DateFormat('dd/MM').format(card.nextDueDate!)}';
    }

    return 'Vence dia ${card.dueDay}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CardsEmpty extends StatelessWidget {
  const _CardsEmpty({required this.onCreatePressed});

  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.credit_card_off_rounded,
            size: 46,
            color: AppColors.violet,
          ),
          const SizedBox(height: 14),
          Text(
            'Nenhum cartao ativo cadastrado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione um cartao para acompanhar limite, vencimento e comprometimento com um visual novo.',
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
              foregroundColor: AppColors.violet,
              side: BorderSide(color: AppColors.violet.withValues(alpha: 0.34)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            icon: const Icon(Icons.add_card_rounded),
            label: const Text(
              'Cadastrar cartao',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.data});

  final _OverviewCardData data;

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

class _OverviewCardData {
  const _OverviewCardData({
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final IconData icon;

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

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

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

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

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
            label,
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.64)
                : colorScheme.onSurface.withValues(alpha: 0.60),
            fontSize: 12,
          ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? Colors.white
        : context.theme.colorScheme.onSurface;
    final secondaryTextColor = isDark
        ? Colors.white.withValues(alpha: 0.64)
        : context.theme.colorScheme.onSurface.withValues(alpha: 0.60);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MiniBlock extends StatelessWidget {
  const _MiniBlock({required this.label, required this.value});

  final String label;
  final String value;

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
              color: context.theme.colorScheme.onSurface,
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

Color _parseColor(String? colorHex, Color fallback) {
  final normalized = colorHex?.replaceFirst('#', '');
  if (normalized == null || normalized.length != 6) {
    return fallback;
  }

  return Color(int.parse('FF$normalized', radix: 16));
}
