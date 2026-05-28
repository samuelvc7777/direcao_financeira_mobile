import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Modelo de dados visual para o status de uma corrida.
class RideStatusData {
  const RideStatusData({required this.label, required this.color});

  factory RideStatusData.from(String status) {
    switch (status) {
      case 'FINISHED':
        return const RideStatusData(
          label: 'Finalizada',
          color: AppColors.emerald,
        );
      case 'CANCELED':
      case 'CANCELLED':
        return const RideStatusData(label: 'Cancelada', color: AppColors.rose);
      case 'PENDING':
        return const RideStatusData(label: 'Pendente', color: AppColors.amber);
      default:
        return RideStatusData(label: status, color: AppColors.sky);
    }
  }

  final String label;
  final Color color;
}

/// Modelo de dados para um tile de metrica.
class RideMetricData {
  const RideMetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

/// Opcao visual de forma de pagamento usada na finalizacao da corrida.
class RidePaymentOption {
  const RidePaymentOption({
    required this.code,
    required this.label,
    required this.icon,
  });

  final String code;
  final String label;
  final IconData icon;

  static const creditOrDebitCard = RidePaymentOption(
    code: 'CARD',
    label: 'Cartao credito e debito',
    icon: Icons.credit_card_rounded,
  );

  static const cash = RidePaymentOption(
    code: 'CASH',
    label: 'Dinheiro',
    icon: Icons.payments_rounded,
  );

  static const pix = RidePaymentOption(
    code: 'PIX',
    label: 'Pix',
    icon: Icons.pix_rounded,
  );

  static const voucher = RidePaymentOption(
    code: 'VOUCHER',
    label: 'Voucher',
    icon: Icons.confirmation_number_rounded,
  );

  static const all = <RidePaymentOption>[creditOrDebitCard, cash, pix, voucher];
}

/// Formata um valor em centavos para string monetaria BRL.
String formatRideCurrency(int cents) {
  final value = cents / 100;
  return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}
