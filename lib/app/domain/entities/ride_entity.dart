class RideEntity {
  final int id;
  final String status;
  final String appName;
  final String? paymentMethod;
  final DateTime? createdAt;
  final int grossValueCents;
  final String date;
  final String time;
  final String origin;
  final String destination;
  final String? rideType;
  final String passenger;
  final double totalKm;
  final int totalTimeSeconds;
  final int durationMinutes;
  final int gainPerKmCents;
  final int gainPerHourCents;

  const RideEntity({
    required this.id,
    required this.status,
    required this.appName,
    required this.paymentMethod,
    required this.createdAt,
    required this.grossValueCents,
    required this.date,
    required this.time,
    required this.origin,
    required this.destination,
    this.rideType,
    required this.passenger,
    required this.totalKm,
    required this.totalTimeSeconds,
    required this.durationMinutes,
    required this.gainPerKmCents,
    required this.gainPerHourCents,
  });
}
