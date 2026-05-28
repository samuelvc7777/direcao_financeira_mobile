import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'costs_gains_wizard_controller.dart';

class CostsGainsWizardStepPresentation {
  const CostsGainsWizardStepPresentation({
    required this.title,
    required this.subtitle,
    required this.cardTitle,
    required this.cardSubtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String cardTitle;
  final String cardSubtitle;
  final IconData icon;
  final Color accent;
}

CostsGainsWizardStepPresentation wizardStepPresentation(
  CostsGainsWizardStep step,
) {
  switch (step) {
    case CostsGainsWizardStep.goal:
      return const CostsGainsWizardStepPresentation(
        title: 'Seu Objetivo',
        subtitle: 'Quanto voce quer ganhar de lucro no mes?',
        cardTitle: 'Meta de lucro mensal',
        cardSubtitle: 'Quanto voce quer levar para casa no final do mes?',
        icon: Icons.emoji_events_rounded,
        accent: Color(0xFF3B82F6),
      );
    case CostsGainsWizardStep.journey:
      return const CostsGainsWizardStepPresentation(
        title: 'Jornada',
        subtitle: 'Quanto tempo voce vai trabalhar?',
        cardTitle: 'Sua jornada',
        cardSubtitle: 'Informe sua rotina de trabalho',
        icon: Icons.schedule_rounded,
        accent: AppColors.primary,
      );
    case CostsGainsWizardStep.mileage:
      return const CostsGainsWizardStepPresentation(
        title: 'Quilometragem',
        subtitle: 'Quantos KMs voce pretende rodar?',
        cardTitle: 'Quilometragem',
        cardSubtitle: 'Quantos quilometros voce roda por dia?',
        icon: Icons.alt_route_rounded,
        accent: AppColors.amber,
      );
    case CostsGainsWizardStep.vehicle:
      return const CostsGainsWizardStepPresentation(
        title: 'Veiculo',
        subtitle: 'Custos fixos mensais do carro',
        cardTitle: 'Custos do veiculo',
        cardSubtitle: 'Despesas fixas mensais',
        icon: Icons.directions_car_filled_rounded,
        accent: AppColors.emerald,
      );
    case CostsGainsWizardStep.fuel:
      return const CostsGainsWizardStepPresentation(
        title: 'Combustivel',
        subtitle: 'Preco e consumo do veiculo',
        cardTitle: 'Combustivel',
        cardSubtitle: 'Preco medio e autonomia do veiculo',
        icon: Icons.local_gas_station_rounded,
        accent: AppColors.rose,
      );
    case CostsGainsWizardStep.platform:
      return const CostsGainsWizardStepPresentation(
        title: 'Plataforma',
        subtitle: 'Taxa opcional dos apps de corrida',
        cardTitle: 'Taxa da plataforma',
        cardSubtitle: 'Preencha apenas se voce souber esse custo',
        icon: Icons.percent_rounded,
        accent: AppColors.secondary,
      );
  }
}
