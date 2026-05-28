import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/responsive.dart';
import '../../widgets/custom_app_bar.dart';
import 'journey_controller.dart';
import 'widgets/journey_status_banner.dart';
import 'widgets/operational_metrics_section.dart';
import 'widgets/metric_period_selector.dart';

class OperationalMetricsView extends GetView<JourneyController> {
  const OperationalMetricsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Métricas Operacionais',
        showBackButton: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final horizontalPadding = width < 360
                ? 8.0
                : width < 430
                ? Responsive.hp(context, 4.0)
                : 16.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      JourneyStatusBanner(),
                      SizedBox(height: 16),
                      MetricPeriodSelector(),
                      SizedBox(height: 24),
                      OperationalMetricsSection(),
                      SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
