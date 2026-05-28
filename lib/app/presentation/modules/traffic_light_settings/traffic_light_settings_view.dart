import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/traffic_light_settings_entity.dart';
import '../../widgets/custom_app_bar.dart';
import 'traffic_light_settings_controller.dart';
import 'widgets/traffic_light_monitored_apps_section.dart';

class TrafficLightSettingsView extends GetView<TrafficLightSettingsController> {
  const TrafficLightSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Configurar Semáforo',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.hp(context, 5),
          vertical: Responsive.vp(context, 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'PREVIEW AO VIVO', isLive: true),
            SizedBox(height: Responsive.vp(context, 2)),
            const _PreviewCard(),
            SizedBox(height: Responsive.vp(context, 2.6)),
            _buildSectionHeader(
              context,
              'Limites do Semáforo',
              icon: Icons.traffic_rounded,
            ),
            SizedBox(height: Responsive.vp(context, 1.2)),
            const _ThresholdsSection(),
            SizedBox(height: Responsive.vp(context, 2.6)),
            Obx(
              () => _buildSectionHeader(
                context,
                'Apps Monitorados',
                icon: Icons.grid_view_rounded,
                trailing:
                    '${controller.selectedMonitoredAppsCount} selecionados',
              ),
            ),
            SizedBox(height: Responsive.vp(context, 1.0)),
            const TrafficLightMonitoredAppsSection(),
            SizedBox(height: Responsive.vp(context, 2.4)),
            _buildSectionHeader(
              context,
              'Posição na Tela',
              icon: Icons.grid_view_rounded,
            ),
            SizedBox(height: Responsive.vp(context, 2)),
            _PositionSelector(),
            SizedBox(height: Responsive.vp(context, 4)),
            _buildSectionHeader(
              context,
              'Tema do Card',
              icon: Icons.palette_rounded,
            ),
            SizedBox(height: Responsive.vp(context, 2)),
            _ThemeSelector(),
            SizedBox(height: Responsive.vp(context, 4)),
            Obx(
              () => _buildSectionHeader(
                context,
                'Indicadores',
                icon: Icons.dashboard_customize_rounded,
                trailing:
                    '${controller.selectedIndicatorsCount}/4 selecionados',
              ),
            ),
            SizedBox(height: Responsive.vp(context, 2)),
            _IndicatorsGrid(),
            SizedBox(height: Responsive.vp(context, 4)),
            _buildSectionHeader(
              context,
              'Ajustes Visuais',
              icon: Icons.tune_rounded,
            ),
            SizedBox(height: Responsive.vp(context, 2)),
            _VisualAdjustments(),
            SizedBox(height: Responsive.vp(context, 4)),
            _ColorBlindToggle(),
            SizedBox(height: Responsive.vp(context, 5)),
            _SaveButton(),
            SizedBox(height: Responsive.vp(context, 5)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    bool isLive = false,
    IconData? icon,
    String? trailing,
  }) {
    final colorScheme = context.theme.colorScheme;

    return Row(
      children: [
        if (isLive)
          Container(
            width: Responsive.sp(context, 8),
            height: Responsive.sp(context, 8),
            margin: EdgeInsets.only(right: Responsive.sp(context, 8)),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        if (icon != null) ...[
          Icon(
            icon,
            size: Responsive.sp(context, 20),
            color: colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: Responsive.sp(context, 8)),
        ],
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: Responsive.sp(context, 13),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: Responsive.sp(context, 12),
            ),
          ),
        if (isLive)
          Text(
            'Mude as opções abaixo',
            style: TextStyle(
              color: AppColors.primary.withValues(alpha: 0.7),
              fontSize: Responsive.sp(context, 12),
            ),
          ),
      ],
    );
  }
}

class _PreviewCard extends GetView<TrafficLightSettingsController> {
  const _PreviewCard();

  static const Map<String, double> _previewMetricValues = <String, double>{
    'R\$/Km': 2.35,
    'R\$/Hora': 52.80,
    'Lucro/H': 38.90,
    'Nota': 4.9,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Obx(() {
      final previewTheme = _TrafficLightPreviewTheme.fromSettings(
        controller.selectedTheme.value,
      );
      final activeIndicators = controller.orderedActiveIndicators.isEmpty
          ? const ['R\$/Km', 'R\$/Hora', 'Lucro/H']
          : controller.orderedActiveIndicators;
      final signalStatus = _resolveSignalStatus(activeIndicators);
      final signalColor = _resolveSignalColor(
        signalStatus,
        controller.colorBlindMode.value,
      );

      return Container(
        height: Responsive.vp(context, 50),
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(Responsive.sp(context, 32)),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(painter: _GridPainter()),
              ),
            ),
            Container(
              width: Responsive.hp(context, 55),
              height: Responsive.vp(context, 45),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Responsive.sp(context, 30)),
                border: Border.all(color: colorScheme.outlineVariant, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Responsive.sp(context, 28)),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: Responsive.vp(context, 1),
                      left: Responsive.hp(context, 2),
                      right: Responsive.hp(context, 2),
                      child: _buildRideMockup(context),
                    ),
                    _buildTrafficLightPositioned(
                      context,
                      controller.selectedPosition.value,
                      Opacity(
                        opacity: (controller.opacity.value / 100).clamp(
                          0.0,
                          1.0,
                        ),
                        child: _buildTrafficLightPreview(
                          context,
                          previewTheme,
                          activeIndicators,
                          signalColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRideMockup(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(Responsive.sp(context, 10)),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(Responsive.sp(context, 16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: Responsive.sp(context, 12),
                backgroundColor: Colors.deepPurpleAccent,
              ),
              SizedBox(width: Responsive.sp(context, 8)),
              Text(
                'Ricardo Silva',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: Responsive.sp(context, 10),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.sp(context, 4),
                  vertical: Responsive.sp(context, 2),
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    Responsive.sp(context, 4),
                  ),
                ),
                child: Text(
                  '4.98',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: Responsive.sp(context, 8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Divider(height: Responsive.vp(context, 1.5)),
          _buildMockAddress(
            context,
            Colors.blue,
            'Shopping Cidade São Paulo',
            '1.2 km',
          ),
          SizedBox(height: Responsive.vp(context, 0.5)),
          _buildMockAddress(
            context,
            Colors.red,
            'Aeroporto de Congonhas',
            '8.5 km',
          ),
          SizedBox(height: Responsive.vp(context, 1)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: Responsive.vp(context, 0.8),
            ),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(Responsive.sp(context, 8)),
            ),
            alignment: Alignment.center,
            child: Text(
              'Aceitar • R\$ 35,40',
              style: TextStyle(
                color: Colors.white,
                fontSize: Responsive.sp(context, 10),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficLightPreview(
    BuildContext context,
    _TrafficLightPreviewTheme previewTheme,
    List<String> activeIndicators,
    Color signalColor,
  ) {
    final baseFontSize = controller.fontSize.value;
    final isSidePosition =
        controller.selectedPosition.value == TrafficLightPosition.esquerda ||
        controller.selectedPosition.value == TrafficLightPosition.direita;
    final previewWidth = isSidePosition
        ? Responsive.hp(context, 31)
        : Responsive.hp(context, 46);
    final monitoredApp = controller.monitoredApps.entries
        .firstWhere(
          (entry) => entry.value,
          orElse: () => const MapEntry('App', true),
        )
        .key;

    return Container(
      width: previewWidth,
      constraints: BoxConstraints(minHeight: Responsive.vp(context, 9.6)),
      padding: EdgeInsets.all(Responsive.sp(context, 11)),
      decoration: BoxDecoration(
        color: previewTheme.backgroundColor,
        borderRadius: BorderRadius.circular(Responsive.sp(context, 18)),
        border: Border.all(
          color: signalColor,
          width: Responsive.sp(context, 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: Responsive.sp(context, 16),
            offset: Offset(0, Responsive.sp(context, 6)),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSidePosition)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: activeIndicators.map((name) {
                return Padding(
                  padding: EdgeInsets.only(bottom: Responsive.vp(context, 0.8)),
                  child: _buildMockMetric(
                    context,
                    label: _overlayMetricLabel(name),
                    value: _formatPreviewValue(name),
                    color: signalColor,
                    theme: previewTheme,
                    baseFontSize: baseFontSize,
                  ),
                );
              }).toList(),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: activeIndicators
                  .map(
                    (name) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: name == activeIndicators.last
                              ? 0
                              : Responsive.sp(
                                  context,
                                  activeIndicators.length > 3 ? 4 : 8,
                                ),
                        ),
                        child: _buildMockMetric(
                          context,
                          label: _overlayMetricLabel(name),
                          value: _formatPreviewValue(name),
                          color: signalColor,
                          theme: previewTheme,
                          baseFontSize: baseFontSize,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          SizedBox(height: Responsive.vp(context, 1.3)),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.sp(context, 8),
                  vertical: Responsive.sp(context, 4),
                ),
                decoration: BoxDecoration(
                  color: previewTheme.badgeBackgroundColor,
                  borderRadius: BorderRadius.circular(
                    Responsive.sp(context, 6),
                  ),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.hp(context, isSidePosition ? 16 : 12),
                  ),
                  child: Text(
                    controller.displayMonitoredAppLabel(monitoredApp).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: previewTheme.badgeTextColor,
                      fontSize: Responsive.sp(
                        context,
                        _scaledFont(baseFontSize, 0.34),
                      ),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              SizedBox(width: Responsive.sp(context, 8)),
              Expanded(
                child: Text(
                  '${_formatDuration(controller.cardDuration.value.toInt())} - 18.3km',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: previewTheme.primaryTextColor,
                    fontSize: Responsive.sp(
                      context,
                      _scaledFont(baseFontSize, 0.58),
                    ),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficLightPositioned(
    BuildContext context,
    TrafficLightPosition position,
    Widget child,
  ) {
    final horizontal = Responsive.hp(context, 2);
    final vertical = Responsive.vp(context, 2);

    switch (position) {
      case TrafficLightPosition.topo:
        return Positioned(
          top: vertical,
          left: 0,
          right: 0,
          child: Align(alignment: Alignment.topCenter, child: child),
        );
      case TrafficLightPosition.esquerda:
        return Positioned(top: vertical, left: horizontal, child: child);
      case TrafficLightPosition.direita:
        return Positioned(top: vertical, right: horizontal, child: child);
      case TrafficLightPosition.rodape:
        return Positioned(
          bottom: Responsive.vp(context, 6),
          left: 0,
          right: 0,
          child: Align(alignment: Alignment.bottomCenter, child: child),
        );
    }
  }

  Widget _buildMockMetric(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required _TrafficLightPreviewTheme theme,
    required double baseFontSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: theme.labelColor,
            fontSize: Responsive.sp(context, _scaledFont(baseFontSize, 0.42)),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: Responsive.vp(context, 0.35)),
        Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: Responsive.sp(context, 4),
              height: Responsive.sp(context, 21),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(Responsive.sp(context, 6)),
              ),
            ),
            SizedBox(width: Responsive.sp(context, 6)),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      color: theme.primaryTextColor,
                      fontSize: Responsive.sp(
                        context,
                        _scaledFont(baseFontSize, 0.74),
                      ),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMockAddress(
    BuildContext context,
    Color color,
    String text,
    String dist,
  ) {
    final colorScheme = context.theme.colorScheme;

    return Row(
      children: [
        Icon(Icons.circle, color: color, size: Responsive.sp(context, 6)),
        SizedBox(width: Responsive.sp(context, 6)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: Responsive.sp(context, 8),
            ),
          ),
        ),
        Text(
          dist,
          style: TextStyle(
            color: Colors.blue,
            fontSize: Responsive.sp(context, 8),
          ),
        ),
      ],
    );
  }

  _PreviewSignalStatus _resolveSignalStatus(List<String> activeIndicators) {
    final statuses = <_PreviewSignalStatus>[];

    if (activeIndicators.contains('R\$/Km')) {
      statuses.add(
        _evaluateThreshold(
          _previewMetricValues['R\$/Km']!,
          controller.gainPerKmBad.value,
          controller.gainPerKmGood.value,
        ),
      );
    }

    if (activeIndicators.contains('R\$/Hora') ||
        activeIndicators.contains('Lucro/H')) {
      statuses.add(
        _evaluateThreshold(
          _previewMetricValues['R\$/Hora']!,
          controller.gainPerHourBad.value,
          controller.gainPerHourGood.value,
        ),
      );
    }

    if (activeIndicators.contains('Nota')) {
      statuses.add(
        _evaluateThreshold(
          _previewMetricValues['Nota']!,
          controller.passengerRatingBad.value,
          controller.passengerRatingGood.value,
        ),
      );
    }

    if (statuses.isEmpty) {
      return _PreviewSignalStatus.good;
    }

    if (statuses.contains(_PreviewSignalStatus.bad)) {
      return _PreviewSignalStatus.bad;
    }
    if (statuses.contains(_PreviewSignalStatus.medium)) {
      return _PreviewSignalStatus.medium;
    }
    return _PreviewSignalStatus.good;
  }

  _PreviewSignalStatus _evaluateThreshold(
    double value,
    double badThreshold,
    double goodThreshold,
  ) {
    if (value < badThreshold) {
      return _PreviewSignalStatus.bad;
    }
    if (value >= goodThreshold) {
      return _PreviewSignalStatus.good;
    }
    return _PreviewSignalStatus.medium;
  }

  Color _resolveSignalColor(_PreviewSignalStatus status, bool colorBlindMode) {
    if (colorBlindMode) {
      switch (status) {
        case _PreviewSignalStatus.good:
          return const Color(0xFF1F78FF);
        case _PreviewSignalStatus.medium:
          return const Color(0xFFF39C12);
        case _PreviewSignalStatus.bad:
          return const Color(0xFF7E57C2);
      }
    }

    switch (status) {
      case _PreviewSignalStatus.good:
        return const Color(0xFF18B663);
      case _PreviewSignalStatus.medium:
        return const Color(0xFFF39C12);
      case _PreviewSignalStatus.bad:
        return const Color(0xFFE74C3C);
    }
  }

  String _overlayMetricLabel(String name) {
    if (name == 'Lucro/H') {
      return 'Lucro';
    }
    return name;
  }

  String _formatPreviewValue(String name) {
    final value = _previewMetricValues[name] ?? 0.0;
    if (name == 'Nota') {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(2);
  }

  String _formatDuration(int seconds) {
    final minutes = seconds * 4;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h${remainingMinutes.toString().padLeft(2, '0')}m';
  }

  double _scaledFont(double base, double factor) {
    return (base * factor).clamp(6.0, 22.0);
  }
}

class _TrafficLightPreviewTheme {
  final Color backgroundColor;
  final Color primaryTextColor;
  final Color labelColor;
  final Color badgeBackgroundColor;
  final Color badgeTextColor;

  const _TrafficLightPreviewTheme({
    required this.backgroundColor,
    required this.primaryTextColor,
    required this.labelColor,
    required this.badgeBackgroundColor,
    required this.badgeTextColor,
  });

  factory _TrafficLightPreviewTheme.fromSettings(TrafficLightTheme theme) {
    switch (theme) {
      case TrafficLightTheme.claro:
        return _TrafficLightPreviewTheme(
          backgroundColor: Colors.white,
          primaryTextColor: const Color(0xFF161616),
          labelColor: const Color(0xFF7A7A7A),
          badgeBackgroundColor: const Color(0xFF111111),
          badgeTextColor: Colors.white,
        );
      case TrafficLightTheme.escuro:
        return _TrafficLightPreviewTheme(
          backgroundColor: const Color(0xFF131313),
          primaryTextColor: const Color(0xFFF7F7F7),
          labelColor: const Color(0xFFA6A6A6),
          badgeBackgroundColor: const Color(0xFFF2F2F2),
          badgeTextColor: const Color(0xFF111111),
        );
      case TrafficLightTheme.verde:
        return _TrafficLightPreviewTheme(
          backgroundColor: const Color(0xFFEAF8F0),
          primaryTextColor: const Color(0xFF0B2F1D),
          labelColor: const Color(0xFF3D6B57),
          badgeBackgroundColor: const Color(0xFF0B2F1D),
          badgeTextColor: Colors.white,
        );
    }
  }
}

enum _PreviewSignalStatus { good, medium, bad }

class _ThresholdsSection extends GetView<TrafficLightSettingsController> {
  const _ThresholdsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ThresholdEditorCard(
          title: 'Ganho por KM',
          subtitle: 'Valores por km rodado',
          icon: Icons.alt_route_rounded,
          accent: const Color(0xFF10B981),
          badLabel: 'Ruim',
          goodLabel: 'Bom',
          badController: controller.gainPerKmBadController,
          goodController: controller.gainPerKmGoodController,
          onBadDecrement: controller.decrementGainPerKmBad,
          onBadIncrement: controller.incrementGainPerKmBad,
          onGoodDecrement: controller.decrementGainPerKmGood,
          onGoodIncrement: controller.incrementGainPerKmGood,
          onBadSubmitted: controller.updateGainPerKmBad,
          onGoodSubmitted: controller.updateGainPerKmGood,
        ),
        SizedBox(height: Responsive.vp(context, 1.2)),
        _ThresholdEditorCard(
          title: 'Ganho por Hora',
          subtitle: 'Valores por hora trabalhada',
          icon: Icons.schedule_rounded,
          accent: Colors.deepPurpleAccent,
          badLabel: 'Ruim',
          goodLabel: 'Bom',
          badController: controller.gainPerHourBadController,
          goodController: controller.gainPerHourGoodController,
          onBadDecrement: controller.decrementGainPerHourBad,
          onBadIncrement: controller.incrementGainPerHourBad,
          onGoodDecrement: controller.decrementGainPerHourGood,
          onGoodIncrement: controller.incrementGainPerHourGood,
          onBadSubmitted: controller.updateGainPerHourBad,
          onGoodSubmitted: controller.updateGainPerHourGood,
        ),
        SizedBox(height: Responsive.vp(context, 1.2)),
        _ThresholdEditorCard(
          title: 'Avaliação do Passageiro',
          subtitle: 'Nota mínima ideal',
          icon: Icons.person_rounded,
          accent: Colors.amber,
          badLabel: 'Ruim',
          goodLabel: 'Bom',
          badController: controller.passengerRatingBadController,
          goodController: controller.passengerRatingGoodController,
          onBadDecrement: controller.decrementPassengerRatingBad,
          onBadIncrement: controller.incrementPassengerRatingBad,
          onGoodDecrement: controller.decrementPassengerRatingGood,
          onGoodIncrement: controller.incrementPassengerRatingGood,
          onBadSubmitted: controller.updatePassengerRatingBad,
          onGoodSubmitted: controller.updatePassengerRatingGood,
        ),
      ],
    );
  }
}

class _ThresholdEditorCard extends StatelessWidget {
  const _ThresholdEditorCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.badLabel,
    required this.goodLabel,
    required this.badController,
    required this.goodController,
    required this.onBadDecrement,
    required this.onBadIncrement,
    required this.onGoodDecrement,
    required this.onGoodIncrement,
    required this.onBadSubmitted,
    required this.onGoodSubmitted,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String badLabel;
  final String goodLabel;
  final TextEditingController badController;
  final TextEditingController goodController;
  final VoidCallback onBadDecrement;
  final VoidCallback onBadIncrement;
  final VoidCallback onGoodDecrement;
  final VoidCallback onGoodIncrement;
  final ValueChanged<String> onBadSubmitted;
  final ValueChanged<String> onGoodSubmitted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(Responsive.sp(context, 14)),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : colorScheme.surface,
        borderRadius: BorderRadius.circular(Responsive.sp(context, 18)),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: Responsive.sp(context, 34),
                height: Responsive.sp(context, 34),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(
                    Responsive.sp(context, 12),
                  ),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: Responsive.sp(context, 18),
                ),
              ),
              SizedBox(width: Responsive.sp(context, 10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : colorScheme.onSurface,
                        fontSize: Responsive.sp(context, 16),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white38
                            : colorScheme.onSurface.withValues(alpha: 0.54),
                        fontSize: Responsive.sp(context, 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.vp(context, 1.4)),
          Row(
            children: [
              Expanded(
                child: _ThresholdValueBox(
                  label: badLabel,
                  controller: badController,
                  borderColor: Colors.redAccent,
                  onDecrement: onBadDecrement,
                  onIncrement: onBadIncrement,
                  onSubmitted: onBadSubmitted,
                ),
              ),
              SizedBox(width: Responsive.sp(context, 10)),
              Expanded(
                child: _ThresholdValueBox(
                  label: goodLabel,
                  controller: goodController,
                  borderColor: Colors.greenAccent,
                  onDecrement: onGoodDecrement,
                  onIncrement: onGoodIncrement,
                  onSubmitted: onGoodSubmitted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThresholdValueBox extends StatelessWidget {
  const _ThresholdValueBox({
    required this.label,
    required this.controller,
    required this.borderColor,
    required this.onDecrement,
    required this.onIncrement,
    required this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final Color borderColor;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark
                ? Colors.white70
                : colorScheme.onSurface.withValues(alpha: 0.72),
            fontSize: Responsive.sp(context, 12),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: Responsive.vp(context, 0.8)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.sp(context, 10),
            vertical: Responsive.sp(context, 8),
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black
                : colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(Responsive.sp(context, 14)),
            border: Border.all(color: borderColor.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              _ThresholdIconButton(
                icon: Icons.remove_rounded,
                color: borderColor,
                onTap: onDecrement,
              ),
              SizedBox(width: Responsive.sp(context, 8)),
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: onSubmitted,
                  onEditingComplete: () => onSubmitted(controller.text),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white : colorScheme.onSurface,
                    fontSize: Responsive.sp(context, 15),
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              SizedBox(width: Responsive.sp(context, 8)),
              _ThresholdIconButton(
                icon: Icons.add_rounded,
                color: borderColor,
                onTap: onIncrement,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThresholdIconButton extends StatelessWidget {
  const _ThresholdIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: EdgeInsets.all(Responsive.sp(context, 2)),
        child: Icon(icon, color: color, size: Responsive.sp(context, 20)),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _PositionSelector extends GetView<TrafficLightSettingsController> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildItem(
          context,
          TrafficLightPosition.topo,
          Icons.vertical_align_top_rounded,
          'Topo',
        ),
        _buildItem(
          context,
          TrafficLightPosition.esquerda,
          Icons.align_horizontal_left_rounded,
          'Esquerda',
        ),
        _buildItem(
          context,
          TrafficLightPosition.direita,
          Icons.align_horizontal_right_rounded,
          'Direita',
        ),
        _buildItem(
          context,
          TrafficLightPosition.rodape,
          Icons.vertical_align_bottom_rounded,
          'Rodapé',
        ),
      ],
    );
  }

  Widget _buildItem(
    BuildContext context,
    TrafficLightPosition pos,
    IconData icon,
    String label,
  ) {
    final colorScheme = context.theme.colorScheme;

    return Obx(() {
      final isSelected = controller.selectedPosition.value == pos;
      return GestureDetector(
        onTap: () => controller.selectedPosition.value = pos,
        child: Container(
          width: (Responsive.width(context) - 70) / 4,
          padding: EdgeInsets.symmetric(vertical: Responsive.vp(context, 1.5)),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(Responsive.sp(context, 16)),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : colorScheme.outlineVariant,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.primary
                    : colorScheme.onSurfaceVariant,
                size: Responsive.sp(context, 24),
              ),
              SizedBox(height: Responsive.vp(context, 1)),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  fontSize: Responsive.sp(context, 11),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _ThemeSelector extends GetView<TrafficLightSettingsController> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildItem(
          context,
          TrafficLightTheme.claro,
          'Claro',
          Colors.white,
          Colors.black,
        ),
        _buildItem(
          context,
          TrafficLightTheme.escuro,
          'Escuro',
          const Color(0xFF1A1A1A),
          Colors.white,
        ),
        _buildItem(
          context,
          TrafficLightTheme.verde,
          'Verde',
          const Color(0xFF034D35),
          Colors.white,
        ),
      ],
    );
  }

  Widget _buildItem(
    BuildContext context,
    TrafficLightTheme theme,
    String label,
    Color bg,
    Color text,
  ) {
    final colorScheme = context.theme.colorScheme;

    return Obx(() {
      final isSelected = controller.selectedTheme.value == theme;
      return GestureDetector(
        onTap: () => controller.selectedTheme.value = theme,
        child: Column(
          children: [
            Container(
              width: (Responsive.width(context) - 60) / 3,
              height: Responsive.vp(context, 8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(Responsive.sp(context, 16)),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : colorScheme.outlineVariant,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 2, height: 20, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '2.35',
                    style: TextStyle(color: text, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 2, height: 20, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '52',
                    style: TextStyle(color: text, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.vp(context, 1)),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : colorScheme.onSurfaceVariant,
                fontSize: Responsive.sp(context, 12),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _IndicatorsGrid extends GetView<TrafficLightSettingsController> {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _buildIndicator(context, 'R\$/Km', Icons.speed_rounded, '1'),
        _buildIndicator(context, 'R\$/Hora', Icons.timer_outlined, '2'),
        _buildIndicator(context, 'Lucro/H', Icons.trending_up_rounded, '4'),
        _buildIndicator(context, 'Nota', Icons.person_rounded, '3'),
      ],
    );
  }

  Widget _buildIndicator(
    BuildContext context,
    String name,
    IconData icon,
    String number,
  ) {
    final colorScheme = context.theme.colorScheme;

    return Obx(() {
      final isActive = controller.indicators[name] ?? false;
      return GestureDetector(
        onTap: () => controller.toggleIndicator(name),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.hp(context, 3),
            vertical: Responsive.vp(context, 1),
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(Responsive.sp(context, 16)),
            border: Border.all(
              color: isActive ? AppColors.primary : colorScheme.outlineVariant,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.sp(context, 8),
                  vertical: Responsive.sp(context, 2),
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(
                    Responsive.sp(context, 8),
                  ),
                ),
                child: Text(
                  number,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: Responsive.sp(context, 9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                icon,
                size: Responsive.sp(context, 20),
                color: isActive
                    ? AppColors.primary
                    : colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: Responsive.vp(context, 0.5)),
              Text(
                name,
                style: TextStyle(
                  color: isActive
                      ? AppColors.primary
                      : colorScheme.onSurfaceVariant,
                  fontSize: Responsive.sp(context, 11),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      );
    });
  }
}

class _VisualAdjustments extends GetView<TrafficLightSettingsController> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(Responsive.sp(context, 20)),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(Responsive.sp(context, 24)),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _buildSliderRow(
            context,
            'Tamanho da Fonte',
            controller.fontSize,
            10,
            30,
          ),
          SizedBox(height: Responsive.vp(context, 2.5)),
          _buildSliderRow(context, 'Opacidade', controller.opacity, 0, 100),
          SizedBox(height: Responsive.vp(context, 2.5)),
          _buildSliderRow(
            context,
            'Duração do Card',
            controller.cardDuration,
            5,
            30,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow(
    BuildContext context,
    String label,
    RxDouble value,
    double min,
    double max,
  ) {
    final colorScheme = context.theme.colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  _getIcon(label),
                  size: Responsive.sp(context, 18),
                  color: AppColors.primary,
                ),
                SizedBox(width: Responsive.sp(context, 8)),
                Text(
                  label,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: Responsive.sp(context, 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.sp(context, 8),
                vertical: Responsive.sp(context, 4),
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Responsive.sp(context, 8)),
              ),
              child: Obx(
                () => Text(
                  label == 'Opacidade'
                      ? '${value.value.toInt()}%'
                      : (label == 'Duração do Card'
                            ? '${value.value.toInt()}s'
                            : '${value.value.toInt()}'),
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: Responsive.sp(context, 12),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        Obx(
          () => Slider(
            value: value.value,
            min: min,
            max: max,
            activeColor: AppColors.primary,
            inactiveColor: colorScheme.outlineVariant,
            thumbColor: AppColors.primary,
            onChanged: (v) => value.value = v,
          ),
        ),
      ],
    );
  }

  IconData _getIcon(String label) {
    if (label.contains('Fonte')) return Icons.text_fields_rounded;
    if (label.contains('Opacidade')) return Icons.opacity_rounded;
    return Icons.timer_outlined;
  }
}

class _ColorBlindToggle extends GetView<TrafficLightSettingsController> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(Responsive.sp(context, 20)),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(Responsive.sp(context, 24)),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            Icons.accessibility_new_rounded,
            color: AppColors.primary,
            size: Responsive.sp(context, 24),
          ),
          SizedBox(width: Responsive.sp(context, 12)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modo daltônico',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: Responsive.sp(context, 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Usar paleta adaptada no preview',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: Responsive.sp(context, 12),
                ),
              ),
            ],
          ),
          const Spacer(),
          Obx(
            () => Switch(
              value: controller.colorBlindMode.value,
              onChanged: (v) => controller.colorBlindMode.value = v,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends GetView<TrafficLightSettingsController> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      height: Responsive.vp(context, 7),
      child: ElevatedButton.icon(
        onPressed: controller.saveSettings,
        icon: Icon(
          Icons.save_rounded,
          color: colorScheme.onPrimary,
          size: Responsive.sp(context, 20),
        ),
        label: Text(
          'Salvar Configurações',
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontSize: Responsive.sp(context, 16),
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.sp(context, 16)),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
