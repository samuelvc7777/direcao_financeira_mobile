class OnlineHourlyProjectionEntity {
  const OnlineHourlyProjectionEntity({
    required this.historicalHourlyCents,
    required this.offeredRideHourlyCents,
    required this.projectedHourlyCents,
    required this.historicalEarningsCents,
    required this.historicalOnlineTimeSeconds,
    required this.projectedEarningsCents,
    required this.projectedOnlineTimeSeconds,
  });

  final int historicalHourlyCents;
  final int offeredRideHourlyCents;
  final int projectedHourlyCents;
  final int historicalEarningsCents;
  final int historicalOnlineTimeSeconds;
  final int projectedEarningsCents;
  final int projectedOnlineTimeSeconds;

  int get hourlyDeltaCents => projectedHourlyCents - historicalHourlyCents;

  double get impactPercent {
    if (historicalHourlyCents <= 0) {
      return projectedHourlyCents > 0 ? 100.0 : 0.0;
    }

    return ((projectedHourlyCents - historicalHourlyCents) /
            historicalHourlyCents) *
        100;
  }

  bool get improvesHistoricalAverage =>
      projectedHourlyCents >= historicalHourlyCents;
}
