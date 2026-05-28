import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/credit_card_entity.dart';
import '../../widgets/app_loading_indicator.dart';
import '../home/widgets/invoice_payment_sheet.dart';
import 'credit_cards_controller.dart';
import 'widgets/credit_card_form_sheet.dart';

class CreditCardsView extends GetView<CreditCardsController> {
  const CreditCardsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingScreen(
            label: 'Carregando cartões...',
            accentColor: AppColors.cardsAccent,
          );
        }

        final error = controller.errorMessage.value;
        if (error != null) {
          return _ErrorState(
            message: error,
            onRetry: controller.loadCreditCards,
          );
        }

        return _CreditCardsBody(
          activeCards: controller.activeCards,
          inactiveCards: controller.inactiveCards,
          onCreatePressed: () => _showCardForm(),
          onCardPressed: (card) => _showCardForm(cardId: card.id),
          onPayPressed: (card) => _showInvoicePaymentSheet(context, card),
          controller: controller,
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCardForm(),
        backgroundColor: AppColors.cardsAccent,
        elevation: 8,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  void _showCardForm({int? cardId}) {
    final card = cardId == null
        ? null
        : controller.creditCards.firstWhereOrNull((item) => item.id == cardId);

    Get.bottomSheet(
      CreditCardFormSheet(card: card, controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _showInvoicePaymentSheet(
    BuildContext context,
    CreditCardEntity card,
  ) async {
    await showInvoicePaymentSheet(
      context: context,
      card: card,
      accounts: controller.bankAccounts,
      onSubmit: (result) {
        return controller.submitInvoicePayment(
          card: card,
          bankAccount: result.bankAccount,
          mode: result.mode,
          amountCents: result.amountCents,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// BODY PRINCIPAL
// ─────────────────────────────────────────────────────────

class _CreditCardsBody extends StatelessWidget {
  const _CreditCardsBody({
    required this.activeCards,
    required this.inactiveCards,
    required this.onCreatePressed,
    required this.onCardPressed,
    required this.onPayPressed,
    required this.controller,
  });

  final List<CreditCardEntity> activeCards;
  final List<CreditCardEntity> inactiveCards;
  final VoidCallback onCreatePressed;
  final void Function(CreditCardEntity) onCardPressed;
  final void Function(CreditCardEntity) onPayPressed;
  final CreditCardsController controller;

  @override
  Widget build(BuildContext context) {
    if (activeCards.isEmpty && inactiveCards.isEmpty) {
      return _EmptyState(onCreatePressed: onCreatePressed);
    }

    final totalLimit = activeCards.fold<int>(0, (sum, c) => sum + c.limitCents);
    final totalUsed = activeCards.fold<int>(
      0,
      (sum, c) => sum + (c.limitCents - c.availableLimitCents),
    );
    final totalAvailable = totalLimit - totalUsed;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // ── SliverAppBar Hero ──
        _HeroSliverAppBar(
          totalLimit: totalLimit,
          totalUsed: totalUsed,
          totalAvailable: totalAvailable,
          activeCount: activeCards.length,
          inactiveCount: inactiveCards.length,
        ),

        // ── Resumo de Limites ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: _LimitSummaryBar(
              totalLimit: totalLimit,
              totalUsed: totalUsed,
            ),
          ),
        ),

        // ── Cartões Ativos ──
        if (activeCards.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: _SectionLabel(
                title: 'Cartões Ativos',
                count: activeCards.length,
                color: AppColors.cardsAccent,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.builder(
              itemCount: activeCards.length,
              itemBuilder: (context, index) {
                final card = activeCards[index];
                return _CreditCardTile(
                  card: card,
                  controller: controller,
                  onTap: () => onCardPressed(card),
                  onPayPressed: card.canPayInvoice
                      ? () => onPayPressed(card)
                      : null,
                );
              },
            ),
          ),
        ],

        // ── Cartões Inativos ──
        if (inactiveCards.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: _SectionLabel(
                title: 'Pausados',
                count: inactiveCards.length,
                color: Colors.grey,
                subtle: true,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.builder(
              itemCount: inactiveCards.length,
              itemBuilder: (context, index) {
                final card = inactiveCards[index];
                return Opacity(
                  opacity: 0.55,
                  child: _CreditCardTile(
                    card: card,
                    controller: controller,
                    onTap: () => onCardPressed(card),
                    onPayPressed: null,
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
    required this.totalLimit,
    required this.totalUsed,
    required this.totalAvailable,
    required this.activeCount,
    required this.inactiveCount,
  });

  final int totalLimit;
  final int totalUsed;
  final int totalAvailable;
  final int activeCount;
  final int inactiveCount;

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final onSurface = context.theme.colorScheme.onSurface;
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return SliverAppBar(
      expandedHeight: 290,
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
                      AppColors.cardsAccent.withValues(alpha: 0.20),
                      context.theme.scaffoldBackgroundColor,
                    ]
                  : [
                      AppColors.cardsAccent.withValues(alpha: 0.08),
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
                  // Ícone + Título
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.cardsAccent,
                              AppColors.cardsAccent.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cardsAccent.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.credit_card_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meus Cartões',
                            style: TextStyle(
                              color: onSurface,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Limites e faturas',
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

                  // Fatura total usada
                  Text(
                    formatter.format(totalUsed / 100.0),
                    style: TextStyle(
                      color: isDark ? Colors.white : onSurface,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Fatura total acumulada',
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.45),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pills + Limite disponível
                  Row(
                    children: [
                      _StatusPill(
                        label: '$activeCount ativos',
                        color: AppColors.cardsAccent,
                      ),
                      const SizedBox(width: 8),
                      if (inactiveCount > 0)
                        _StatusPill(
                          label: '$inactiveCount pausados',
                          color: Colors.grey,
                        ),
                      const Spacer(),
                      Text(
                        '${formatter.format(totalAvailable / 100.0)} livre',
                        style: TextStyle(
                          color: AppColors.emerald.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
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
// BARRA RESUMO DE LIMITE
// ─────────────────────────────────────────────────────────

class _LimitSummaryBar extends StatelessWidget {
  const _LimitSummaryBar({required this.totalLimit, required this.totalUsed});

  final int totalLimit;
  final int totalUsed;

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final onSurface = context.theme.colorScheme.onSurface;
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final usedPercent = totalLimit > 0 ? totalUsed / totalLimit : 0.0;
    final barColor = usedPercent >= 0.85
        ? AppColors.rose
        : usedPercent >= 0.60
        ? AppColors.amber
        : AppColors.cardsAccent;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? onSurface.withValues(alpha: 0.04)
            : context.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: barColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Uso do limite total',
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(usedPercent * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: barColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: usedPercent.clamp(0.0, 1.0),
              backgroundColor: onSurface.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Usado: ${formatter.format(totalUsed / 100.0)}',
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.45),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Limite: ${formatter.format(totalLimit / 100.0)}',
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.45),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// CARD DE CARTÃO DE CRÉDITO
// ─────────────────────────────────────────────────────────

class _CreditCardTile extends StatelessWidget {
  const _CreditCardTile({
    required this.card,
    required this.controller,
    required this.onTap,
    required this.onPayPressed,
    this.isInactive = false,
  });

  final CreditCardEntity card;
  final CreditCardsController controller;
  final VoidCallback onTap;
  final VoidCallback? onPayPressed;
  final bool isInactive;

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final onSurface = context.theme.colorScheme.onSurface;
    final accentColor = controller.colorFromHex(card.color);
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final usedPercent = card.usedPercentage;
    final usedColor = usedPercent >= 0.85
        ? AppColors.rose
        : usedPercent >= 0.60
        ? AppColors.amber
        : accentColor;

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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withValues(alpha: isDark ? 0.20 : 0.08),
                  isDark
                      ? onSurface.withValues(alpha: 0.03)
                      : context.theme.colorScheme.surface,
                ],
              ),
              border: Border.all(
                color: accentColor.withValues(alpha: isDark ? 0.30 : 0.14),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: isDark ? 0.10 : 0.06),
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
                  // Header: Icone + Nome + Brand
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
                        child: const Icon(
                          Icons.credit_card_rounded,
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
                              card.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  card.brand,
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

                  // Fatura + Limite
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fatura atual',
                              style: TextStyle(
                                color: onSurface.withValues(alpha: 0.45),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatter.format(card.usedLimit),
                              style: TextStyle(
                                color: onSurface,
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
                            'Disponível',
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.35),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatter.format(card.availableLimit),
                            style: TextStyle(
                              color: AppColors.emerald.withValues(alpha: 0.85),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Barra de uso
                  _UsageBar(usedPercent: usedPercent, barColor: usedColor),

                  const SizedBox(height: 14),

                  // Chips: Fechamento + Vencimento + Uso %
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.event_rounded,
                        label: 'Fecha dia ${card.closingDay}',
                        color: accentColor,
                      ),
                      _InfoChip(
                        icon: Icons.calendar_today_rounded,
                        label: 'Vence dia ${card.dueDay}',
                        color: accentColor,
                      ),
                      _InfoChip(
                        icon: Icons.pie_chart_rounded,
                        label:
                            '${(usedPercent * 100).toStringAsFixed(0)}% usado',
                        color: usedColor,
                      ),
                    ],
                  ),
                  if (onPayPressed != null) ...[
                    const SizedBox(height: 16),
                    Obx(() {
                      final isPaying = controller.isProcessingInvoicePayment(
                        card.id,
                      );

                      return SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: isPaying ? null : onPayPressed,
                          style: FilledButton.styleFrom(
                            backgroundColor: card.isInvoiceOverdue
                                ? AppColors.rose
                                : accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: isPaying
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.payments_rounded),
                          label: Text(
                            isPaying
                                ? 'Pagando...'
                                : 'Pagar ${formatter.format(card.payableInvoice)}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      );
                    }),
                  ],
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
// BARRA DE USO DO LIMITE
// ─────────────────────────────────────────────────────────

class _UsageBar extends StatelessWidget {
  const _UsageBar({required this.usedPercent, required this.barColor});

  final double usedPercent;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.theme.colorScheme.onSurface;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 7,
            child: LinearProgressIndicator(
              value: usedPercent.clamp(0.0, 1.0),
              backgroundColor: onSurface.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.65),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

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
                backgroundColor: AppColors.cardsAccent,
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
                    AppColors.cardsAccent.withValues(alpha: 0.18),
                    AppColors.cardsAccent.withValues(alpha: 0.06),
                  ],
                ),
                border: Border.all(
                  color: AppColors.cardsAccent.withValues(alpha: 0.15),
                ),
              ),
              child: const Icon(
                Icons.credit_card_off_rounded,
                color: AppColors.cardsAccent,
                size: 44,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Nenhum cartão cadastrado',
              style: TextStyle(
                color: onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Cadastre seu primeiro cartão e controle limites e faturas.',
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
              label: const Text('Cadastrar cartão'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.cardsAccent,
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
