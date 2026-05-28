import '../../../domain/entities/costs_gains_settings_entity.dart';
export '../../../domain/entities/costs_gains_settings_entity.dart';

class CostsGainsDraft {
  const CostsGainsDraft({
    required this.desiredNetProfitCents,
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
  });

  final int desiredNetProfitCents;
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

  factory CostsGainsDraft.empty() {
    return const CostsGainsDraft(
      desiredNetProfitCents: 0,
      workDaysPerWeek: 0,
      workHoursPerDay: 0,
      kmPerDay: 0,
      financeOrRentMonthlyCents: 0,
      insuranceMonthlyCents: 0,
      maintenanceMonthlyCents: 0,
      annualTaxesCents: 0,
      fuelPricePerLiterCents: 0,
      kmPerLiter: 0,
      platformFeeType: PlatformFeeType.fixed,
      platformFeeValue: 0,
    );
  }

  factory CostsGainsDraft.defaults() {
    return const CostsGainsDraft(
      desiredNetProfitCents: 400000,
      workDaysPerWeek: 6,
      workHoursPerDay: 12,
      kmPerDay: 150,
      financeOrRentMonthlyCents: 310400,
      insuranceMonthlyCents: 0,
      maintenanceMonthlyCents: 0,
      annualTaxesCents: 0,
      fuelPricePerLiterCents: 600,
      kmPerLiter: 10.5,
      platformFeeType: PlatformFeeType.fixed,
      platformFeeValue: 0,
    );
  }

  double get desiredNetProfit => desiredNetProfitCents / 100;
  double get financeOrRentMonthly => financeOrRentMonthlyCents / 100;
  double get insuranceMonthly => insuranceMonthlyCents / 100;
  double get maintenanceMonthly => maintenanceMonthlyCents / 100;
  double get annualTaxes => annualTaxesCents / 100;
  double get fuelPricePerLiter => fuelPricePerLiterCents / 100;

  double get annualTaxesMonthly => annualTaxes / 12;
  double get fixedMonthlyCosts =>
      financeOrRentMonthly +
      insuranceMonthly +
      maintenanceMonthly +
      annualTaxesMonthly;

  double get monthlyWorkDays => workDaysPerWeek * 4.33;
  double get monthlyWorkHours => monthlyWorkDays * workHoursPerDay;
  double get monthlyKm => monthlyWorkDays * kmPerDay;
  double get estimatedFuel =>
      kmPerLiter <= 0 ? 0 : (monthlyKm / kmPerLiter) * fuelPricePerLiter;

  double get grossMonthlyGoal {
    final subtotal = desiredNetProfit + fixedMonthlyCosts + estimatedFuel;
    if (platformFeeType == PlatformFeeType.fixed) {
      return subtotal + platformFeeValue;
    }

    final factor = 1 - (platformFeeValue / 100);
    if (factor <= 0) {
      return subtotal;
    }

    return subtotal / factor;
  }

  double get platformFeeAmount {
    if (platformFeeType == PlatformFeeType.fixed) {
      return platformFeeValue;
    }

    return grossMonthlyGoal * (platformFeeValue / 100);
  }

  double get totalCosts =>
      fixedMonthlyCosts + estimatedFuel + platformFeeAmount;
  double get weeklyTarget => grossMonthlyGoal / 4.33;
  double get dailyTarget =>
      monthlyWorkDays <= 0 ? 0 : grossMonthlyGoal / monthlyWorkDays;
  double get perKmTarget => monthlyKm <= 0 ? 0 : grossMonthlyGoal / monthlyKm;
  double get perHourTarget =>
      monthlyWorkHours <= 0 ? 0 : grossMonthlyGoal / monthlyWorkHours;

  String get platformLabel => platformFeeType == PlatformFeeType.fixed
      ? 'Taxa fixa da plataforma'
      : 'Taxa percentual da plataforma';

  CostsGainsDraft copyWith({
    int? desiredNetProfitCents,
    int? workDaysPerWeek,
    double? workHoursPerDay,
    double? kmPerDay,
    int? financeOrRentMonthlyCents,
    int? insuranceMonthlyCents,
    int? maintenanceMonthlyCents,
    int? annualTaxesCents,
    int? fuelPricePerLiterCents,
    double? kmPerLiter,
    PlatformFeeType? platformFeeType,
    double? platformFeeValue,
  }) {
    return CostsGainsDraft(
      desiredNetProfitCents:
          desiredNetProfitCents ?? this.desiredNetProfitCents,
      workDaysPerWeek: workDaysPerWeek ?? this.workDaysPerWeek,
      workHoursPerDay: workHoursPerDay ?? this.workHoursPerDay,
      kmPerDay: kmPerDay ?? this.kmPerDay,
      financeOrRentMonthlyCents:
          financeOrRentMonthlyCents ?? this.financeOrRentMonthlyCents,
      insuranceMonthlyCents:
          insuranceMonthlyCents ?? this.insuranceMonthlyCents,
      maintenanceMonthlyCents:
          maintenanceMonthlyCents ?? this.maintenanceMonthlyCents,
      annualTaxesCents: annualTaxesCents ?? this.annualTaxesCents,
      fuelPricePerLiterCents:
          fuelPricePerLiterCents ?? this.fuelPricePerLiterCents,
      kmPerLiter: kmPerLiter ?? this.kmPerLiter,
      platformFeeType: platformFeeType ?? this.platformFeeType,
      platformFeeValue: platformFeeValue ?? this.platformFeeValue,
    );
  }

  factory CostsGainsDraft.fromEntity(CostsGainsSettingsEntity entity) {
    return CostsGainsDraft(
      desiredNetProfitCents: entity.desiredMonthlyProfitCents,
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
    );
  }

  CostsGainsSettingsEntity toEntity({required int userId, int? id}) {
    return CostsGainsSettingsEntity(
      id: id,
      userId: userId,
      desiredMonthlyProfitCents: desiredNetProfitCents,
      workDaysPerWeek: workDaysPerWeek,
      workHoursPerDay: workHoursPerDay,
      kmPerDay: kmPerDay,
      financeOrRentMonthlyCents: financeOrRentMonthlyCents,
      insuranceMonthlyCents: insuranceMonthlyCents,
      maintenanceMonthlyCents: maintenanceMonthlyCents,
      annualTaxesCents: annualTaxesCents,
      fuelPricePerLiterCents: fuelPricePerLiterCents,
      kmPerLiter: kmPerLiter,
      platformFeeType: platformFeeType,
      platformFeeValue: platformFeeValue,
    );
  }
}
