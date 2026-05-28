class RideScreenshotImportEntity {
  const RideScreenshotImportEntity({
    required this.platformName,
    this.detectedAt,
    this.passengerName,
    this.passengerRating,
    this.paymentMethod,
    this.grossValueCents,
    this.originAddress,
    this.destinationAddress,
    this.tripNumber,
  });

  final String platformName;
  final DateTime? detectedAt;
  final String? passengerName;
  final double? passengerRating;
  final String? paymentMethod;
  final int? grossValueCents;
  final String? originAddress;
  final String? destinationAddress;
  final String? tripNumber;
}
