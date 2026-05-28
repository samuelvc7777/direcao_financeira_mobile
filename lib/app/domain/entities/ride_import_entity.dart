class RideImportEntity {
  final int rideId;
  final String status;
  final String appName;
  final String? paymentMethod;
  final int grossValueCents;
  final String date;
  final String time;
  final bool isAlreadyImported;

  const RideImportEntity({
    required this.rideId,
    required this.status,
    required this.appName,
    required this.paymentMethod,
    required this.grossValueCents,
    required this.date,
    required this.time,
    required this.isAlreadyImported,
  });

  RideImportEntity copyWith({
    int? rideId,
    String? status,
    String? appName,
    String? paymentMethod,
    int? grossValueCents,
    String? date,
    String? time,
    bool? isAlreadyImported,
  }) {
    return RideImportEntity(
      rideId: rideId ?? this.rideId,
      status: status ?? this.status,
      appName: appName ?? this.appName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      grossValueCents: grossValueCents ?? this.grossValueCents,
      date: date ?? this.date,
      time: time ?? this.time,
      isAlreadyImported: isAlreadyImported ?? this.isAlreadyImported,
    );
  }

  bool get isEligible =>
      status.trim().toUpperCase() == 'FINISHED' &&
      grossValueCents > 0 &&
      (paymentMethod?.trim().isNotEmpty ?? false) &&
      !isAlreadyImported;

  String get groupKey {
    final normalized = paymentMethod?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'DESCONHECIDO';
    }
    return normalized.toUpperCase();
  }
}

class RideImportGroupEntity {
  final String paymentMethodCode;
  final String paymentMethodLabel;
  final List<RideImportEntity> rides;

  const RideImportGroupEntity({
    required this.paymentMethodCode,
    required this.paymentMethodLabel,
    required this.rides,
  });

  int get totalCents =>
      rides.fold<int>(0, (total, ride) => total + ride.grossValueCents);
}
