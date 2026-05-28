class RideStatisticsEntity {
  final int totalRides;
  final int grossEarningsCents;
  final int netEarningsCents;
  final int totalCostsCents;
  final double ridesTotalKm;
  final int ridesTotalTime;

  const RideStatisticsEntity({
    required this.totalRides,
    required this.grossEarningsCents,
    required this.netEarningsCents,
    required this.totalCostsCents,
    required this.ridesTotalKm,
    required this.ridesTotalTime,
  });
}

class JourneyStatisticsEntity {
  final int totalShifts;
  final String totalTime;
  final String averageTime;
  final String drivenKm;
  final double totalDrivenKmValue;
  final RideStatisticsEntity rideStats;

  const JourneyStatisticsEntity({
    required this.totalShifts,
    required this.totalTime,
    required this.averageTime,
    required this.drivenKm,
    required this.totalDrivenKmValue,
    required this.rideStats,
  });
}
