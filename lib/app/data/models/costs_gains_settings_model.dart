import '../../domain/entities/costs_gains_settings_entity.dart';

class CostsGainsSettingsModel extends CostsGainsSettingsEntity {
  const CostsGainsSettingsModel({
    super.id,
    required super.userId,
    required super.desiredMonthlyProfitCents,
    required super.workDaysPerWeek,
    required super.workHoursPerDay,
    required super.kmPerDay,
    required super.financeOrRentMonthlyCents,
    required super.insuranceMonthlyCents,
    required super.maintenanceMonthlyCents,
    required super.annualTaxesCents,
    required super.fuelPricePerLiterCents,
    required super.kmPerLiter,
    required super.platformFeeType,
    required super.platformFeeValue,
    super.createdAt,
    super.updatedAt,
  });

  factory CostsGainsSettingsModel.fromMap(Map<String, dynamic> map) {
    return CostsGainsSettingsModel(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      desiredMonthlyProfitCents: map['desiredMonthlyProfitCents'] as int? ?? 0,
      workDaysPerWeek: map['workDaysPerWeek'] as int? ?? 0,
      workHoursPerDay: (map['workHoursPerDay'] as num? ?? 0).toDouble(),
      kmPerDay: (map['kmPerDay'] as num? ?? 0).toDouble(),
      financeOrRentMonthlyCents: map['financeOrRentMonthlyCents'] as int? ?? 0,
      insuranceMonthlyCents: map['insuranceMonthlyCents'] as int? ?? 0,
      maintenanceMonthlyCents: map['maintenanceMonthlyCents'] as int? ?? 0,
      annualTaxesCents: map['annualTaxesCents'] as int? ?? 0,
      fuelPricePerLiterCents: map['fuelPricePerLiterCents'] as int? ?? 0,
      kmPerLiter: (map['kmPerLiter'] as num? ?? 0).toDouble(),
      platformFeeType: _platformFeeTypeFromString(
        map['platformFeeType']?.toString(),
      ),
      platformFeeValue: (map['platformFeeValue'] as num? ?? 0).toDouble(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'desiredMonthlyProfitCents': desiredMonthlyProfitCents,
      'workDaysPerWeek': workDaysPerWeek,
      'workHoursPerDay': workHoursPerDay,
      'kmPerDay': kmPerDay,
      'financeOrRentMonthlyCents': financeOrRentMonthlyCents,
      'insuranceMonthlyCents': insuranceMonthlyCents,
      'maintenanceMonthlyCents': maintenanceMonthlyCents,
      'annualTaxesCents': annualTaxesCents,
      'fuelPricePerLiterCents': fuelPricePerLiterCents,
      'kmPerLiter': kmPerLiter,
      'platformFeeType': platformFeeType.name,
      'platformFeeValue': platformFeeValue,
      if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
    };
  }

  factory CostsGainsSettingsModel.fromEntity(CostsGainsSettingsEntity entity) {
    return CostsGainsSettingsModel(
      id: entity.id,
      userId: entity.userId,
      desiredMonthlyProfitCents: entity.desiredMonthlyProfitCents,
      workDaysPerWeek: entity.workDaysPerWeek,
      workHoursPerDay: entity.workHoursPerDay,
      kmPerDay: entity.kmPerDay,
      financeOrRentMonthlyCents: entity.financeOrRentMonthlyCents,
      insuranceMonthlyCents: entity.insuranceMonthlyCents,
      maintenanceMonthlyCents: entity.maintenanceMonthlyCents,
      annualTaxesCents: entity.annualTaxesCents,
      fuelPricePerLiterCents: entity.fuelPricePerLiterCents,
      kmPerLiter: entity.kmPerLiter,
      platformFeeType: entity.platformFeeType,
      platformFeeValue: entity.platformFeeValue,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  static PlatformFeeType _platformFeeTypeFromString(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'percentage':
        return PlatformFeeType.percentage;
      case 'fixed':
      default:
        return PlatformFeeType.fixed;
    }
  }
}
