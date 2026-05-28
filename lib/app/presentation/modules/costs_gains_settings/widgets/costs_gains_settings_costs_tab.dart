import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../costs_gains_settings_controller.dart';

class CostsGainsSettingsCostsTab extends StatelessWidget {
  CostsGainsSettingsCostsTab({super.key, required this.controller});

  final CostsGainsSettingsController controller;
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  @override
  Widget build(BuildContext context) {
    final kmBad = controller.perKmTarget * 0.6;
    final hourBad = controller.perHourTarget * 0.6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TrafficLightHeroCard(),
        const SizedBox(height: 8),
        _ThresholdCard(
          icon: Icons.alt_route_rounded,
          iconBackground: AppColors.emerald,
          title: 'Ganho por KM',
          subtitle: 'Por km rodado',
          badLabel: 'Ruim',
          goodLabel: 'Bom',
          badValue: _currency.format(kmBad),
          goodValue: _currency.format(controller.perKmTarget),
          cardTint: AppColors.emerald,
        ),
        const SizedBox(height: 8),
        _ThresholdCard(
          icon: Icons.schedule_rounded,
          iconBackground: AppColors.primary,
          title: 'Ganho por Hora',
          subtitle: 'Por hora trabalhada',
          badLabel: 'Ruim',
          goodLabel: 'Bom',
          badValue: _currency.format(hourBad),
          goodValue: _currency.format(controller.perHourTarget),
          cardTint: AppColors.primary,
        ),
        const SizedBox(height: 8),
        const _ThresholdCard(
          icon: Icons.person_rounded,
          iconBackground: AppColors.amber,
          title: 'Nota do Passageiro',
          subtitle: 'Nota minima ideal',
          badLabel: 'Ruim',
          goodLabel: 'Bom',
          badValue: '4.6',
          goodValue: '5.0',
          cardTint: AppColors.amber,
        ),
        const SizedBox(height: 8),
        _PrimaryAction(
          onPressed: controller.openTrafficLightSettings,
          icon: Icons.save_rounded,
          label: 'Salvar Configuracoes',
        ),
      ],
    );
  }
}

class CostsGainsSettingsDetailsSection extends StatelessWidget {
  const CostsGainsSettingsDetailsSection({
    super.key,
    required this.currency,
    required this.controller,
  });

  final NumberFormat currency;
  final CostsGainsSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colorScheme.onSurface.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.14),
                      ),
                    ),
                    child: const Icon(
                      Icons.calculate_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalhamento',
                          style: context.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Como chegamos nesse valor',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.58,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.025),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _CostRow(
                      icon: Icons.build_rounded,
                      iconColor: const Color(0xFF64748B),
                      iconBackground: const Color(0xFFF1F5F9),
                      label: 'Custos fixos mensais',
                      value: currency.format(controller.fixedMonthlyCosts),
                    ),
                    const SizedBox(height: 8),
                    _CostRow(
                      icon: Icons.local_gas_station_rounded,
                      iconColor: AppColors.amber,
                      iconBackground: const Color(0xFFFFF6E8),
                      label: 'Combustivel estimado',
                      value: currency.format(controller.estimatedFuel),
                    ),
                    const SizedBox(height: 8),
                    _CostRow(
                      icon: Icons.percent_rounded,
                      iconColor: AppColors.primary,
                      iconBackground: const Color(0xFFDBEAFE),
                      label: controller.platformLabel,
                      value: currency.format(controller.platformFee),
                    ),
                    const SizedBox(height: 8),
                    Divider(
                      color: colorScheme.onSurface.withValues(alpha: 0.12),
                      height: 1,
                    ),
                    const SizedBox(height: 8),
                    _CostRow(
                      icon: Icons.warning_amber_rounded,
                      iconColor: AppColors.rose,
                      iconBackground: const Color(0xFFFFEEF1),
                      label: 'TOTAL DE CUSTOS',
                      value: currency.format(controller.totalCosts),
                      highlight: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _PrimaryAction(
          onPressed: controller.applyToTrafficLight,
          icon: Icons.traffic_rounded,
          label: 'Aplicar no Semaforo',
        ),
        const SizedBox(height: 8),
        _SecondaryAction(controller: controller),
      ],
    );
  }
}

class _TrafficLightHeroCard extends StatelessWidget {
  const _TrafficLightHeroCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.14),
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _StatusDot(color: AppColors.rose),
              SizedBox(width: 8),
              _StatusDot(color: AppColors.amber),
              SizedBox(width: 8),
              _StatusDot(color: AppColors.emerald),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Configurar Semaforo',
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Defina seus limites para classificar corridas',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.58),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.36),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _ThresholdCard extends StatelessWidget {
  const _ThresholdCard({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.badLabel,
    required this.goodLabel,
    required this.badValue,
    required this.goodValue,
    required this.cardTint,
  });

  final IconData icon;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String badLabel;
  final String goodLabel;
  final String badValue;
  final String goodValue;
  final Color cardTint;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [cardTint.withValues(alpha: 0.12), colorScheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: cardTint.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: cardTint.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cardTint,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: cardTint.withValues(alpha: 0.24),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.58),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Legend(color: AppColors.rose, label: badLabel),
              ),
              Expanded(
                child: _Legend(color: AppColors.emerald, label: goodLabel),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _LimitBox(
                  value: badValue,
                  borderColor: AppColors.rose,
                  iconColor: AppColors.rose,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _LimitBox(
                  value: goodValue,
                  borderColor: AppColors.emerald,
                  iconColor: AppColors.emerald,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.theme.colorScheme.onSurface.withValues(alpha: 0.82),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LimitBox extends StatelessWidget {
  const _LimitBox({
    required this.value,
    required this.borderColor,
    required this.iconColor,
  });

  final String value;
  final Color borderColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.45),
          width: 1.6,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.remove_rounded, color: iconColor, size: 18),
          const Spacer(),
          Text(
            value,
            style: context.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Icon(Icons.add_rounded, color: iconColor, size: 18),
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style:
                (highlight
                        ? context.textTheme.titleMedium
                        : context.textTheme.bodySmall)
                    ?.copyWith(
                      color: colorScheme.onSurface.withValues(
                        alpha: highlight ? 1 : 0.72,
                      ),
                      fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
                    ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: context.textTheme.bodyLarge?.copyWith(
              color: highlight ? AppColors.rose : colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF60A5FA), AppColors.primary],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            minimumSize: const Size(double.infinity, 44),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: Icon(icon, color: Colors.white, size: 16),
          label: Text(
            label,
            style: context.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({required this.controller});

  final CostsGainsSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return OutlinedButton.icon(
      onPressed: () => controller.openAdjustCosts(),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 42),
        side: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        foregroundColor: colorScheme.onSurface.withValues(alpha: 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      icon: const Icon(Icons.edit_rounded, size: 16),
      label: Text(
        'Ajustar meus custos',
        style: context.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.72),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
