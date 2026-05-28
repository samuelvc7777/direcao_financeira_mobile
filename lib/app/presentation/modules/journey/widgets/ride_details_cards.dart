import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/ride_entity.dart';
import 'ride_details_atoms.dart';
import 'ride_details_models.dart';

/// Header hero com gradiente azul, círculos decorativos,
/// chip do app, data/hora e status badge.
class RideHeroHeader extends StatelessWidget {
  const RideHeroHeader({
    super.key,
    required this.ride,
    required this.status,
    required this.isDark,
  });

  final RideEntity ride;
  final RideStatusData status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1B6E), Color(0xFF1A237E), Color(0xFF1565C0)],
        ),
      ),
      child: Stack(
        children: [
          _DecorativeCircle(top: -30, right: -30, size: 180, alpha: 0.04),
          _DecorativeCircle(bottom: -20, left: -40, size: 220, alpha: 0.03),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AppChip(appName: ride.appName),
                  const SizedBox(height: 10),
                  Text(
                    '${ride.date}  •  ${ride.time}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Detalhes da Corrida',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RideStatusBadge(status: status),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Círculo decorativo posicionável para o fundo do header.
class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.alpha,
  });

  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      ),
    );
  }
}

/// Chip com ícone do táxi e nome do app (Uber/99/etc).
class _AppChip extends StatelessWidget {
  const _AppChip({required this.appName});
  final String appName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_taxi_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            appName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card hero com gradiente azul que exibe o valor bruto e passageiro.
class RideValueHeroCard extends StatelessWidget {
  const RideValueHeroCard({super.key, required this.ride, required this.isDark});

  final RideEntity ride;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF1E40AF), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Valor Bruto',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatRideCurrency(ride.grossValueCents),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person_rounded,
                      color: Colors.white.withValues(alpha: 0.65),
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ride.passenger,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.attach_money_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid 2×2 de tiles de métricas da corrida.
class RideMetricsGrid extends StatelessWidget {
  const RideMetricsGrid({super.key, required this.ride, required this.isDark});

  final RideEntity ride;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      RideMetricData(
        label: 'Tempo total',
        value: '${ride.durationMinutes} min',
        icon: Icons.timer_rounded,
        color: AppColors.electricCyan,
      ),
      RideMetricData(
        label: 'Ganho / km',
        value: formatRideCurrency(ride.gainPerKmCents),
        icon: Icons.route_rounded,
        color: AppColors.emerald,
      ),
      RideMetricData(
        label: 'Ganho / hora',
        value: formatRideCurrency(ride.gainPerHourCents),
        icon: Icons.timelapse_rounded,
        color: AppColors.amber,
      ),
      RideMetricData(
        label: 'App',
        value: ride.appName,
        icon: Icons.phone_android_rounded,
        color: AppColors.violet,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: metrics.map((m) => _MetricTile(data: m, isDark: isDark)).toList(),
    );
  }
}

/// Tile individual de uma métrica no grid.
class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.data, required this.isDark});

  final RideMetricData data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: rideCardDecoration(isDark: isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.value,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card visual de rota: Origem → linha gradiente → Destino.
class RideRouteCard extends StatelessWidget {
  const RideRouteCard({super.key, required this.ride, required this.isDark});

  final RideEntity ride;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: rideCardDecoration(isDark: isDark),
      child: Column(
        children: [
          _RouteStop(
            icon: Icons.radio_button_checked_rounded,
            iconColor: AppColors.emerald,
            label: 'Origem',
            value: ride.origin,
            isDark: isDark,
          ),
          if (ride.rideType?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _RouteStop(
              icon: Icons.alt_route_rounded,
              iconColor: AppColors.royalBlue,
              label: 'Rota',
              value: ride.rideType!.trim(),
              isDark: isDark,
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 28,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.emerald.withValues(alpha: 0.6),
                        AppColors.rose.withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          _RouteStop(
            icon: Icons.location_on_rounded,
            iconColor: AppColors.rose,
            label: 'Destino',
            value: ride.destination,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

/// Linha de parada na rota (Origem ou Destino).
class _RouteStop extends StatelessWidget {
  const _RouteStop({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Card de informações gerais: status, passageiro, data e horário.
class RideInfoCard extends StatelessWidget {
  const RideInfoCard({
    super.key,
    required this.ride,
    required this.status,
    required this.isDark,
  });

  final RideEntity ride;
  final RideStatusData status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: rideCardDecoration(isDark: isDark),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.sync_alt_rounded,
            iconColor: status.color,
            label: 'Status',
            isDark: isDark,
            trailing: RideStatusBadge(status: status, compact: true),
          ),
          RideCardDivider(isDark: isDark),
          _InfoRow(
            icon: Icons.person_rounded,
            iconColor: AppColors.sky,
            label: 'Passageiro',
            value: ride.passenger,
            isDark: isDark,
          ),
          RideCardDivider(isDark: isDark),
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.amber,
            label: 'Data',
            value: ride.date,
            isDark: isDark,
          ),
          RideCardDivider(isDark: isDark),
          _InfoRow(
            icon: Icons.access_time_rounded,
            iconColor: AppColors.violet,
            label: 'Horário',
            value: ride.time,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

/// Linha de informação com ícone colorido, label e valor ou widget trailing.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.isDark,
    this.value,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? value;
  final Widget? trailing;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            trailing!
          else if (value != null)
            Text(
              value!,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
