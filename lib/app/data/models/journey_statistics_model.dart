import '../../domain/entities/journey_statistics_entity.dart';

class RideStatisticsModel extends RideStatisticsEntity {
  const RideStatisticsModel({
    required super.totalRides,
    required super.grossEarningsCents,
    required super.netEarningsCents,
    required super.totalCostsCents,
    required super.ridesTotalKm,
    required super.ridesTotalTime,
  });

  factory RideStatisticsModel.fromJson(Map<String, dynamic> json) {
    return RideStatisticsModel(
      totalRides: json['totalRides'] as int? ?? 0,
      grossEarningsCents: json['grossEarningsCents'] as int? ?? 0,
      netEarningsCents: json['netEarningsCents'] as int? ?? 0,
      totalCostsCents: json['totalCostsCents'] as int? ?? 0,
      ridesTotalKm: (json['ridesTotalKm'] as num?)?.toDouble() ?? 0.0,
      ridesTotalTime: json['ridesTotalTime'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRides': totalRides,
      'grossEarningsCents': grossEarningsCents,
      'netEarningsCents': netEarningsCents,
      'totalCostsCents': totalCostsCents,
      'ridesTotalKm': ridesTotalKm,
      'ridesTotalTime': ridesTotalTime,
    };
  }
}

class JourneyStatisticsModel extends JourneyStatisticsEntity {
  const JourneyStatisticsModel({
    required super.totalShifts,
    required super.totalTime,
    required super.averageTime,
    required super.drivenKm,
    required super.totalDrivenKmValue,
    required super.rideStats,
  });

  factory JourneyStatisticsModel.fromJson(Map<String, dynamic> json) {
    return JourneyStatisticsModel(
      totalShifts: json['totalShifts'] as int,
      totalTime: json['totalTime'] as String,
      averageTime: json['averageTime'] as String,
      drivenKm: json['drivenKm'] as String,
      totalDrivenKmValue:
          (json['totalDrivenKmValue'] as num?)?.toDouble() ?? 0.0,
      rideStats: json['rideStats'] != null
          ? RideStatisticsModel.fromJson(
              json['rideStats'] as Map<String, dynamic>,
            )
          : const RideStatisticsModel(
              totalRides: 0,
              grossEarningsCents: 0,
              netEarningsCents: 0,
              totalCostsCents: 0,
              ridesTotalKm: 0.0,
              ridesTotalTime: 0,
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalShifts': totalShifts,
      'totalTime': totalTime,
      'averageTime': averageTime,
      'drivenKm': drivenKm,
      'totalDrivenKmValue': totalDrivenKmValue,
      'rideStats': (rideStats as RideStatisticsModel).toJson(),
    };
  }
}
