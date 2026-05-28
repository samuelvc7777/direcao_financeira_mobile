import '../entities/online_hourly_projection_entity.dart';

class OnlineHourlyProjectionCalculator {
  const OnlineHourlyProjectionCalculator._();

  static int calculateHourlyCents({
    required int earningsCents,
    required int onlineTimeSeconds,
  }) {
    if (earningsCents <= 0 || onlineTimeSeconds <= 0) {
      return 0;
    }

    return ((earningsCents * 3600) / onlineTimeSeconds).round();
  }

  static OnlineHourlyProjectionEntity project({
    required int historicalEarningsCents,
    required int historicalOnlineTimeSeconds,
    required int offeredRideEarningsCents,
    required int offeredRideDurationSeconds,
  }) {
    final sanitizedHistoricalTime = historicalOnlineTimeSeconds < 0
        ? 0
        : historicalOnlineTimeSeconds;
    final sanitizedOfferedTime = offeredRideDurationSeconds < 0
        ? 0
        : offeredRideDurationSeconds;
    final sanitizedHistoricalEarnings =
        sanitizedHistoricalTime <= 0 || historicalEarningsCents <= 0
        ? 0
        : historicalEarningsCents;
    final sanitizedOfferedEarnings =
        sanitizedOfferedTime <= 0 || offeredRideEarningsCents <= 0
        ? 0
        : offeredRideEarningsCents;

    final projectedEarnings =
        sanitizedHistoricalEarnings + sanitizedOfferedEarnings;
    final projectedTime = sanitizedHistoricalTime + sanitizedOfferedTime;

    return OnlineHourlyProjectionEntity(
      historicalHourlyCents: calculateHourlyCents(
        earningsCents: sanitizedHistoricalEarnings,
        onlineTimeSeconds: sanitizedHistoricalTime,
      ),
      offeredRideHourlyCents: calculateHourlyCents(
        earningsCents: sanitizedOfferedEarnings,
        onlineTimeSeconds: sanitizedOfferedTime,
      ),
      projectedHourlyCents: calculateHourlyCents(
        earningsCents: projectedEarnings,
        onlineTimeSeconds: projectedTime,
      ),
      historicalEarningsCents: sanitizedHistoricalEarnings,
      historicalOnlineTimeSeconds: sanitizedHistoricalTime,
      projectedEarningsCents: projectedEarnings,
      projectedOnlineTimeSeconds: projectedTime,
    );
  }
}
