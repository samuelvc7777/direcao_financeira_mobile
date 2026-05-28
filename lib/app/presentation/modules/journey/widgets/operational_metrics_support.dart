part of 'operational_metrics_section.dart';

class _CostDetailGroupCard extends StatelessWidget {
  const _CostDetailGroupCard({
    required this.title,
    required this.totalCents,
    required this.items,
    required this.accentColor,
    required this.icon,
  });

  final String title;
  final int totalCents;
  final List<OperationalCostBreakdownItem> items;
  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A171D)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: accentColor, size: 13),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
              Text(
                _formatCurrencyPtBr(totalCents),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in items) ...[
            _CostDetailRow(
              label: item.label,
              value: _formatCurrencyPtBr(item.amountCents),
            ),
            if (item != items.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _OperationalSummaryWidget extends GetView<JourneyController> {
  const _OperationalSummaryWidget();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF151218)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.rose : colorScheme.shadow).withValues(
              alpha: isDark ? 0.04 : 0.06,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Obx(() {
        final summary = controller.operationalSummaryData;
        final lucro = summary.netEarningsCents;
        final ganhos = summary.grossEarningsCents;
        final custos = summary.totalCostsCents;
        final viagens = summary.totalRides;
        final margem = summary.margin;
        final isPositivo = summary.isPositive;
        final mainColor = isPositivo ? AppColors.emerald : AppColors.rose;
        final grossColor = AppColors.emerald;
        final grossGradientColors = [
          grossColor.withValues(alpha: 0.15),
          grossColor.withValues(alpha: 0.02),
        ];

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: grossGradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: grossColor.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: grossColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.trending_up_rounded,
                                size: 12,
                                color: grossColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ganhos Brutos',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: grossColor.withValues(
                            alpha: isDark ? 0.12 : 0.10,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '$viagens corridas',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formatCurrencyPtBr(ganhos),
                            maxLines: 1,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                      if (ganhos > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6, left: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Margem',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${margem.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: mainColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: controller.toggleOperationalCostBreakdown,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TopSummaryMetric(
                        icon: isPositivo
                            ? Icons.savings_rounded
                            : Icons.money_off_rounded,
                        iconColor: mainColor,
                        title: 'Lucro Líquido',
                        value: _formatCurrencyPtBr(lucro),
                        valueColor: mainColor,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: colorScheme.outlineVariant.withValues(alpha: 0.9),
                    ),
                    Expanded(
                      child: _TopSummaryMetric(
                        icon: Icons.trending_down_rounded,
                        iconColor: AppColors.rose,
                        title: 'Custos Totais',
                        value: _formatCurrencyPtBr(custos),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: summary.isCostBreakdownExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _OperationalCostDetails(controller: controller),
              crossFadeState: summary.isCostBreakdownExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        );
      }),
    );
  }
}

class _OperationalCostDetails extends StatelessWidget {
  const _OperationalCostDetails({required this.controller});

  final JourneyController controller;

  @override
  Widget build(BuildContext context) {
    final breakdown = controller.operationalCostBreakdownData;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.9),
            height: 1,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                'Detalhamento dos Custos',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _CostDetailGroupCard(
            title: 'Custos Variáveis',
            totalCents: breakdown.variableCostsCents,
            items: breakdown.variableItems,
            accentColor: const Color(0xFFF2B84B),
            icon: Icons.local_gas_station_outlined,
          ),
          const SizedBox(height: 12),
          _CostDetailGroupCard(
            title: 'Custos Fixos',
            totalCents: breakdown.fixedCostsCents,
            items: breakdown.fixedItems,
            accentColor: AppColors.rose,
            icon: Icons.business_outlined,
          ),
        ],
      ),
    );
  }
}

class _CostDetailRow extends StatelessWidget {
  const _CostDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.72),
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _TopSummaryMetric extends StatelessWidget {
  const _TopSummaryMetric({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 11),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodsSectionBody extends StatelessWidget {
  const _PaymentMethodsSectionBody();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<JourneyController>();

    return Obx(() {
      final state = controller.paymentMethodsSectionState;

      return AnimatedCrossFade(
        firstChild: const SizedBox.shrink(),
        secondChild: Column(
          children: [
            const SizedBox(height: 10),
            if (state.items.isEmpty)
              const _PaymentMethodsEmptyState()
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: state.items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _PaymentMethodCard(
                            item: item,
                            totalFinishedRides: state.totalFinishedRides,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            if (state.hasUnmappedRides) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  '${state.unmappedCount} corridas finalizadas sem forma de pagamento mapeada.',
                  style: TextStyle(
                    color: context.theme.colorScheme.onSurface.withValues(
                      alpha: 0.54,
                    ),
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ],
        ),
        crossFadeState: state.isExpanded
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 220),
      );
    });
  }
}

class _PaymentMethodsEmptyState extends StatelessWidget {
  const _PaymentMethodsEmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Text(
        'Nenhuma corrida finalizada com forma de pagamento encontrada neste periodo.',
        style: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.70),
          fontSize: 12,
          height: 1.35,
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.item,
    required this.totalFinishedRides,
  });

  final PaymentMethodSummaryItem item;
  final int totalFinishedRides;

  @override
  Widget build(BuildContext context) {
    final metadata = _paymentMethodMetadata(item.code);
    final colorScheme = context.theme.colorScheme;
    final percentage = totalFinishedRides > 0
        ? (item.count / totalFinishedRides) * 100
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: metadata.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: metadata.color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: metadata.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(metadata.icon, color: metadata.color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metadata.label,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.count} corridas',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.70),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: metadata.color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

({String label, IconData icon, Color color}) _paymentMethodMetadata(
  String code,
) {
  switch (code) {
    case 'CARD':
      return (
        label: 'Cartao',
        icon: Icons.credit_card_rounded,
        color: AppColors.royalBlue,
      );
    case 'CASH':
      return (
        label: 'Dinheiro',
        icon: Icons.payments_rounded,
        color: AppColors.emerald,
      );
    case 'PIX':
      return (
        label: 'Pix',
        icon: Icons.pix_rounded,
        color: AppColors.electricCyan,
      );
    case 'VOUCHER':
      return (
        label: 'Voucher',
        icon: Icons.confirmation_number_rounded,
        color: const Color(0xFFF2B84B),
      );
    default:
      return (
        label: code,
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.royalBlue,
      );
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.45, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF3A1118),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.rose.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: _opacity.value,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.rose,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'AO VIVO',
                style: TextStyle(
                  color: AppColors.rose,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.35,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
