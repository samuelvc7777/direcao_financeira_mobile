import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_text_field.dart';
import '../../costs_gains_settings/costs_gains_draft.dart';
import '../costs_gains_wizard_controller.dart';
import '../costs_gains_wizard_presentation.dart';

class CostsGainsWizardStepContent extends StatelessWidget {
  const CostsGainsWizardStepContent({
    super.key,
    required this.controller,
    required this.step,
    required this.presentation,
  });

  final CostsGainsWizardController controller;
  final CostsGainsWizardStep step;
  final CostsGainsWizardStepPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: presentation.accent.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 14,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: presentation.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  presentation.icon,
                  color: presentation.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      presentation.cardTitle,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      presentation.cardSubtitle,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.56),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFields(context),
        ],
      ),
    );
  }

  Widget _buildFields(BuildContext context) {
    switch (step) {
      case CostsGainsWizardStep.goal:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              controller: controller.desiredProfitController,
              label: 'Lucro desejado',
              hint: 'R\$ 4.000,00',
              icon: Icons.attach_money_rounded,
              compact: true,
              keyboardType: TextInputType.number,
              inputFormatters: controller.currencyFormatters,
            ),
            const SizedBox(height: 6),
            _SupportText(text: 'Valor liquido que voce quer ganhar por mes.'),
          ],
        );
      case CostsGainsWizardStep.journey:
        return Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: controller.workDaysController,
                label: 'Dias/semana',
                hint: '6 dias',
                icon: Icons.calendar_today_rounded,
                compact: true,
                keyboardType: TextInputType.number,
                inputFormatters: controller.integerFormatters,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomTextField(
                controller: controller.workHoursController,
                label: 'Horas/dia',
                hint: '12,0 h',
                icon: Icons.schedule_rounded,
                compact: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: controller.decimalFormatters,
              ),
            ),
          ],
        );
      case CostsGainsWizardStep.mileage:
        return CustomTextField(
          controller: controller.kmPerDayController,
          label: 'KM por dia',
          hint: '150 km',
          icon: Icons.speed_rounded,
          compact: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: controller.decimalFormatters,
        );
      case CostsGainsWizardStep.vehicle:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: controller.financeController,
                    label: 'Financ./Aluguel',
                    hint: 'R\$ 0,00',
                    icon: Icons.home_work_outlined,
                    compact: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: controller.currencyFormatters,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextField(
                    controller: controller.insuranceController,
                    label: 'Seguro',
                    hint: 'R\$ 0,00',
                    icon: Icons.shield_outlined,
                    compact: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: controller.currencyFormatters,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: controller.maintenanceController,
              label: 'Manutencao mensal',
              hint: 'R\$ 0,00',
              icon: Icons.build_rounded,
              compact: true,
              keyboardType: TextInputType.number,
              inputFormatters: controller.currencyFormatters,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: controller.annualTaxesController,
              label: 'IPVA + Licenciamento (anual)',
              hint: 'R\$ 0,00',
              icon: Icons.receipt_long_rounded,
              compact: true,
              keyboardType: TextInputType.number,
              inputFormatters: controller.currencyFormatters,
            ),
            const SizedBox(height: 6),
            _SupportText(
              text:
                  'Esse valor anual sera diluido automaticamente no calculo mensal.',
            ),
          ],
        );
      case CostsGainsWizardStep.fuel:
        return Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: controller.fuelPriceController,
                label: 'Preco/Litro',
                hint: 'R\$ 6,00',
                icon: Icons.attach_money_rounded,
                compact: true,
                keyboardType: TextInputType.number,
                inputFormatters: controller.currencyFormatters,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomTextField(
                controller: controller.kmPerLiterController,
                label: 'Km/Litro',
                hint: '10,5 km/L',
                icon: Icons.speed_rounded,
                compact: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: controller.decimalFormatters,
              ),
            ),
          ],
        );
      case CostsGainsWizardStep.platform:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: context.theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: context.theme.colorScheme.onSurface.withValues(
                      alpha: 0.08,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _FeeTypeButton(
                        label: 'Percentual',
                        icon: Icons.percent_rounded,
                        isSelected:
                            controller.selectedPlatformFeeType.value ==
                            PlatformFeeType.percentage,
                        accent: presentation.accent,
                        onTap: () => controller.updatePlatformFeeType(
                          PlatformFeeType.percentage,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _FeeTypeButton(
                        label: 'Fixo',
                        icon: Icons.check_rounded,
                        isSelected:
                            controller.selectedPlatformFeeType.value ==
                            PlatformFeeType.fixed,
                        accent: presentation.accent,
                        onTap: () => controller.updatePlatformFeeType(
                          PlatformFeeType.fixed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Obx(
              () =>
                  controller.selectedPlatformFeeType.value ==
                      PlatformFeeType.fixed
                  ? CustomTextField(
                      controller: controller.platformFeeController,
                      label: 'Valor fixo mensal (opcional)',
                      hint: 'Deixe vazio se nao souber',
                      icon: Icons.account_balance_wallet_outlined,
                      compact: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: controller.currencyFormatters,
                    )
                  : CustomTextField(
                      controller: controller.platformFeeController,
                      label: 'Percentual medio (opcional)',
                      hint: 'Deixe vazio se nao souber',
                      icon: Icons.percent_rounded,
                      compact: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: controller.decimalFormatters,
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Icon(
                          Icons.percent_rounded,
                          color: AppColors.secondary.withValues(alpha: 0.74),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            _SupportText(
              text:
                  'Uber e 99 geralmente ja mostram valores com a taxa descontada. Se voce nao souber a taxa, deixe em branco.',
            ),
          ],
        );
    }
  }
}

class _FeeTypeButton extends StatelessWidget {
  const _FeeTypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isSelected
              ? LinearGradient(colors: [accent.withValues(alpha: 0.88), accent])
              : null,
          color: isSelected ? null : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : colorScheme.onSurface.withValues(alpha: 0.72),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? Colors.white
                    : colorScheme.onSurface.withValues(alpha: 0.78),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportText extends StatelessWidget {
  const _SupportText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textTheme.bodyMedium?.copyWith(
        color: context.theme.colorScheme.onSurface.withValues(alpha: 0.56),
      ),
    );
  }
}
