import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../widgets/app_loading_indicator.dart';
import '../../../../domain/entities/tracked_route_point_entity.dart';
import '../shift_route_controller.dart';

class ShiftRouteContent extends GetView<ShiftRouteController> {
  const ShiftRouteContent({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Obx(() {
      if (controller.isLoading.value) {
        return const AppLoadingScreen(
          label: 'Carregando rota do turno',
          accentColor: AppColors.sky,
        );
      }

      if (controller.errorMessage.value != null) {
        return _ShiftRouteState(
          icon: Icons.map_outlined,
          title: controller.errorMessage.value!,
          actionLabel: 'Tentar novamente',
          onPressed: controller.loadRoute,
        );
      }

      final route = controller.route.value;
      if (route == null || !route.hasPoints) {
        return const _ShiftRouteState(
          icon: Icons.route_outlined,
          title: 'Nenhum ponto de rota foi registrado para este turno.',
        );
      }

      final polylinePoints = route.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
      final center = _calculateCenter(route.points);
      final shift = controller.shift.value;

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          Responsive.hp(context, 4.0).clamp(12.0, 20.0),
          16,
          Responsive.hp(context, 4.0).clamp(12.0, 20.0),
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Card ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surface,
                    colorScheme.surfaceContainerHighest,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.calendar_today_rounded,
                          color: AppColors.royalBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          shift?.date ?? 'Detalhes do Turno',
                          style: context.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MetricChip(
                        icon: Icons.route_rounded,
                        label: '${route.totalDistanceKm.toStringAsFixed(1)} km',
                        subtitle: 'Rastreados',
                        color: AppColors.royalBlue,
                      ),
                      _MetricChip(
                        icon: Icons.pin_drop_rounded,
                        label: '${route.pointCount}',
                        subtitle: 'Pontos',
                        color: AppColors.emerald,
                      ),
                      _MetricChip(
                        icon: Icons.schedule_rounded,
                        label:
                            '${_formatTime(route.startedAt)} - ${_formatTime(route.endedAt)}',
                        subtitle: 'Tempo total',
                        color: AppColors.amber,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Área do Mapa ──────────────────────────────────────
            Container(
              height: 420,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _MapCanvas(
                rawPoints: polylinePoints,
                center: center,
                isFullScreen: false,
              ),
            ),
          ],
        ),
      );
    });
  }

  LatLng _calculateCenter(List<TrackedRoutePointEntity> points) {
    if (points.isEmpty) return const LatLng(0, 0);
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// ── Smart Map Canvas ─────────────────────────

class _MapCanvas extends StatelessWidget {
  final List<LatLng> rawPoints;
  final LatLng center;
  final bool isFullScreen;

  const _MapCanvas({
    required this.rawPoints,
    required this.center,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 14.5),
          children: [
            TileLayer(
              urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
              userAgentPackageName: 'br.com.direcaofinanceira.app',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: rawPoints,
                  strokeWidth: 6,
                  color: AppColors.royalBlue,
                  borderStrokeWidth: 2,
                  borderColor: Theme.of(context).colorScheme.outlineVariant,
                  strokeJoin: StrokeJoin.round,
                  strokeCap: StrokeCap.round,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: rawPoints.first,
                  width: 60,
                  height: 60,
                  child: const _ModernMarker(
                    color: AppColors.emerald,
                    icon: Icons.play_arrow_rounded,
                  ),
                ),
                Marker(
                  point: rawPoints.last,
                  width: 60,
                  height: 60,
                  child: const _ModernMarker(
                    color: AppColors.rose,
                    icon: Icons.stop_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          top: isFullScreen ? MediaQuery.of(context).padding.top + 16 : 16,
          right: isFullScreen ? null : 16,
          left: isFullScreen ? 16 : null,
          child: Material(
            color: AppColors.midnight.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                if (isFullScreen) {
                  Get.back();
                } else {
                  Get.to(
                    () => _FullScreenMapPage(
                      rawPoints: rawPoints,
                      center: center,
                    ),
                    transition: Transition.fadeIn,
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  isFullScreen ? Icons.close_rounded : Icons.fullscreen_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FullScreenMapPage extends StatelessWidget {
  final List<LatLng> rawPoints;
  final LatLng center;

  const _FullScreenMapPage({required this.rawPoints, required this.center});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: _MapCanvas(
        rawPoints: rawPoints,
        center: center,
        isFullScreen: true,
      ),
    );
  }
}

// ── Widgets Extras ─────────────────────────

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModernMarker extends StatelessWidget {
  const _ModernMarker({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.white, width: 2.5),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        // Seta indicando para baixo (pino)
        Container(
          width: 2,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

class _ShiftRouteState extends StatelessWidget {
  const _ShiftRouteState({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
