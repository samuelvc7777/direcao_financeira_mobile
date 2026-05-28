import 'package:direcao_financeira_mobile/app/domain/entities/journey_statistics_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/location_tracking_status_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/ride_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/shift_entity.dart';

RideEntity buildJourneyRideVariant({
  required int id,
  required String status,
  String? paymentMethod,
  int grossValueCents = 3200,
  int durationMinutes = 20,
}) {
  return RideEntity(
    id: id,
    status: status,
    appName: 'Uber',
    paymentMethod: paymentMethod,
    createdAt: DateTime(2026, 1, 10, 8, 30),
    grossValueCents: grossValueCents,
    date: '10/01/2026',
    time: '08:30',
    origin: 'Centro',
    destination: 'Aeroporto',
    passenger: 'Joao',
    totalKm: 5,
    totalTimeSeconds: durationMinutes * 60,
    durationMinutes: durationMinutes,
    gainPerKmCents: 640,
    gainPerHourCents: 9600,
  );
}

ShiftEntity buildJourneyShiftVariant({
  required int index,
  bool isPendingSync = false,
}) {
  return ShiftEntity(
    index: index,
    localId: index,
    remoteShiftId: 100 + index,
    date: '10/01/2026',
    startTime: '08:00',
    endTime: '09:00',
    duration: '01:00:00',
    isPendingSync: isPendingSync,
    hasRoute: true,
  );
}

LocationTrackingStatusEntity buildJourneyTrackingIssue({
  required String issueMessage,
  bool hasBackgroundPermission = false,
}) {
  return LocationTrackingStatusEntity(
    isTrackingActive: false,
    isLocationServiceEnabled: true,
    hasForegroundPermission: true,
    hasBackgroundPermission: hasBackgroundPermission,
    isPreciseLocation: true,
    isPaused: false,
    totalDistanceMeters: 1200,
    idleTimeSeconds: 60,
    issueMessage: issueMessage,
  );
}

JourneyStatisticsEntity buildJourneyStatisticsVariant({
  required int totalRides,
  required int grossEarningsCents,
  required int totalCostsCents,
}) {
  return JourneyStatisticsEntity(
    totalShifts: 2,
    totalTime: '03:00:00',
    averageTime: '01:30:00',
    drivenKm: '30.0 km',
    totalDrivenKmValue: 30,
    rideStats: RideStatisticsEntity(
      totalRides: totalRides,
      grossEarningsCents: grossEarningsCents,
      netEarningsCents: grossEarningsCents - totalCostsCents,
      totalCostsCents: totalCostsCents,
      ridesTotalKm: 12,
      ridesTotalTime: 2400,
    ),
  );
}
