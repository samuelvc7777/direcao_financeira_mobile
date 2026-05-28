enum PlatformFeeType { percentage, fixed }

class CostsGainsSettingsEntity {
  const CostsGainsSettingsEntity({
    this.id,
    required this.userId,
    required this.desiredMonthlyProfitCents,
    required this.workDaysPerWeek,
    required this.workHoursPerDay,
    required this.kmPerDay,
    required this.financeOrRentMonthlyCents,
    required this.insuranceMonthlyCents,
    required this.maintenanceMonthlyCents,
    required this.annualTaxesCents,
    required this.fuelPricePerLiterCents,
    required this.kmPerLiter,
    required this.platformFeeType,
    required this.platformFeeValue,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int userId;
  final int desiredMonthlyProfitCents;
  final int workDaysPerWeek;
  final double workHoursPerDay;
  final double kmPerDay;
  final int financeOrRentMonthlyCents;
  final int insuranceMonthlyCents;
  final int maintenanceMonthlyCents;
  final int annualTaxesCents;
  final int fuelPricePerLiterCents;
  final double kmPerLiter;
  final PlatformFeeType platformFeeType;
  final double platformFeeValue;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
