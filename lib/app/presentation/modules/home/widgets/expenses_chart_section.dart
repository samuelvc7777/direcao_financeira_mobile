import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../home_controller.dart';
import '../home_expense_chart_item.dart';
import 'package:direcao_financeira_mobile/app/core/theme/app_colors.dart';

class ExpensesChartSection extends GetView<HomeController> {
  const ExpensesChartSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final gastos = controller.gastosPorCategoria;
      final totalSaidas = controller.totalSaidas;
      final isVisible = controller.isBalanceVisible.value;

      return LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 430;
          final chartSize = isCompact
              ? (constraints.maxWidth - 40).clamp(160.0, 220.0)
              : 160.0;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: context.theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.sky.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.pie_chart,
                        color: AppColors.sky,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gastos por Categoria',
                            style: TextStyle(
                              color: AppColors.sky,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Distribuicao das suas saidas no periodo',
                            style: TextStyle(
                              color: context.theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (isCompact) ...[
                  Center(child: _buildChart(context, gastos, chartSize)),
                  const SizedBox(height: 20),
                  _buildLegend(context, gastos),
                ] else ...[
                  Row(
                    children: [
                      _buildChart(context, gastos, chartSize),
                      const SizedBox(width: 24),
                      Expanded(child: _buildLegend(context, gastos)),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                Divider(
                  color: context.theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total de saidas',
                      style: TextStyle(
                        color: context.theme.colorScheme.onSurface.withValues(alpha: 0.54),
                        fontSize: 14,
                      ),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isVisible
                              ? 'R\$ ${totalSaidas.toStringAsFixed(2).replaceAll('.', ',')}'
                              : 'R\$ ....',
                          style: const TextStyle(
                            color: AppColors.rose,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Widget _buildChart(
    BuildContext context,
    List<HomeExpenseChartItem> gastos,
    double size,
  ) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutChartPainter(gastos),
        child: Center(
          child: Text(
            '${gastos.isNotEmpty ? gastos.first.percentage.toStringAsFixed(0) : 0}%',
            style: TextStyle(
              color: context.theme.colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context, List<HomeExpenseChartItem> gastos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: gastos.map((g) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: g.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  g.categoryLabel,
                  style: TextStyle(
                    color: context.theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${g.percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: context.theme.colorScheme.onSurface.withValues(alpha: 0.54),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<HomeExpenseChartItem> data;

  _DonutChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 28.0;

    final bgPaint = Paint()
      ..color = Get.theme.colorScheme.onSurface.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    double startAngle = -pi / 2;
    for (final item in data) {
      final sweepAngle = 2 * pi * (item.percentage / 100);
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
