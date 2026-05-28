import 'package:direcao_financeira_mobile/app/data/models/bank_account_model.dart';
import 'package:direcao_financeira_mobile/app/data/models/category_model.dart';
import 'package:direcao_financeira_mobile/app/data/models/credit_card_model.dart';
import 'package:direcao_financeira_mobile/app/data/models/plan_model.dart';
import 'package:direcao_financeira_mobile/app/data/models/subscription_model.dart';
import 'package:direcao_financeira_mobile/app/data/models/transaction_model.dart';
import 'package:direcao_financeira_mobile/app/data/models/user_model.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/active_shift_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/bank_account_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/category_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/journey_statistics_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/location_tracking_status_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/ride_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/shift_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/store_product_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/transaction_entity.dart';

UserModel buildUser({
  int id = 1,
  String email = 'samuel@example.com',
  String name = 'Samuel',
  String? profilePhotoBase64,
}) {
  return UserModel(
    id: id,
    email: email,
    name: name,
    role: 'user',
    isActive: true,
    profilePhotoBase64: profilePhotoBase64,
  );
}

BankAccountModel buildBankAccount({
  int id = 1,
  String name = 'Carteira',
  bool isActive = true,
}) {
  return BankAccountModel(
    id: id,
    name: name,
    bankName: 'Nubank',
    color: '#06B6D4',
    accountType: AccountType.wallet,
    initialBalanceCents: 10000,
    currentBalanceCents: 15000,
    isActive: isActive,
  );
}

CategoryModel buildCategory({
  int id = 1,
  String name = 'Combustivel',
  CategoryType type = CategoryType.expense,
  bool isActive = true,
}) {
  final now = DateTime(2026, 1, 1);
  return CategoryModel(
    id: id,
    userId: 1,
    name: name,
    type: type,
    color: '#038C8C',
    icon: 'fuel',
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

CreditCardModel buildCreditCard({
  int id = 1,
  String name = 'Visa',
  bool isActive = true,
}) {
  return CreditCardModel(
    id: id,
    name: name,
    brand: 'visa',
    color: '#8B5CF6',
    limitCents: 500000,
    availableLimitCents: 350000,
    closingDay: 10,
    dueDay: 20,
    lastFourDigits: '1234',
    isActive: isActive,
  );
}

TransactionModel buildTransaction({
  int id = 1,
  TransactionType type = TransactionType.expense,
  TransactionStatus status = TransactionStatus.cleared,
  AssetType assetType = AssetType.bankAccount,
  DateTime? date,
  String description = 'Posto Shell',
  int? bankAccountId = 1,
  int? creditCardId,
  String? installmentGroupId,
  int? installmentNumber,
  int? installmentCount,
  String? recurrenceGroupId,
  int? recurrenceNumber,
  int? recurrenceCount,
}) {
  return TransactionModel(
    id: id,
    type: type,
    status: status,
    assetType: assetType,
    amountCents: 2500,
    categoryId: 1,
    description: description,
    transactionDate: date ?? DateTime(2026, 1, 10),
    bankAccountId: bankAccountId,
    creditCardId: creditCardId,
    installmentGroupId: installmentGroupId,
    installmentNumber: installmentNumber,
    installmentCount: installmentCount,
    categoryName: 'Combustivel',
    recurrenceGroupId: recurrenceGroupId,
    recurrenceNumber: recurrenceNumber,
    recurrenceCount: recurrenceCount,
  );
}

PlanModel buildPlan({int id = 1, String code = 'premium_monthly'}) {
  return PlanModel(
    id: id,
    code: code,
    name: 'Premium',
    description: 'Plano premium',
    priceCents: 2500,
    durationDays: 30,
    color: '#038C8C',
    isActive: true,
  );
}

SubscriptionModel buildSubscription({
  int id = 1,
  String status = 'ACTIVE',
  PlanModel? plan,
  String? googlePlayProductId,
  String? googlePlayPurchaseToken,
}) {
  return SubscriptionModel(
    id: id,
    status: status,
    autoRenew: true,
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 2, 1),
    googlePlayProductId: googlePlayProductId,
    googlePlayPurchaseToken: googlePlayPurchaseToken,
    plan: plan ?? buildPlan(),
  );
}

StoreProductEntity buildStoreProduct({
  String productId = 'premium_monthly',
  String priceLabel = 'R\$ 25,00',
  String? recurringPriceLabel,
  double rawPrice = 25,
  int? trialDays,
  String? trialLabel,
  String? offerToken,
}) {
  return StoreProductEntity(
    productId: productId,
    title: 'Premium',
    description: 'Plano premium',
    priceLabel: priceLabel,
    recurringPriceLabel: recurringPriceLabel,
    rawPrice: rawPrice,
    currencyCode: 'BRL',
    trialDays: trialDays,
    trialLabel: trialLabel,
    offerToken: offerToken,
  );
}

ActiveShiftEntity buildActiveShift() {
  return ActiveShiftEntity(
    id: 1,
    startTime: DateTime(2026, 1, 10, 8),
    createdAt: DateTime(2026, 1, 10, 8),
    currentDrivenKm: 12.5,
    idleTimeSeconds: 300,
    lowSpeedSince: null,
    lastMotionIdleCheckpointAt: null,
  );
}

LocationTrackingStatusEntity buildTrackingStatus({
  bool isTrackingActive = false,
  bool isLocationServiceEnabled = true,
  bool hasForegroundPermission = true,
  bool hasBackgroundPermission = true,
  bool isPreciseLocation = true,
  bool isPaused = false,
  double totalDistanceMeters = 1000,
  int idleTimeSeconds = 300,
}) {
  return LocationTrackingStatusEntity(
    isTrackingActive: isTrackingActive,
    isLocationServiceEnabled: isLocationServiceEnabled,
    hasForegroundPermission: hasForegroundPermission,
    hasBackgroundPermission: hasBackgroundPermission,
    isPreciseLocation: isPreciseLocation,
    isPaused: isPaused,
    totalDistanceMeters: totalDistanceMeters,
    idleTimeSeconds: idleTimeSeconds,
  );
}

JourneyStatisticsEntity buildJourneyStatistics() {
  return const JourneyStatisticsEntity(
    totalShifts: 1,
    totalTime: '01:00:00',
    averageTime: '01:00:00',
    drivenKm: '10.0 km',
    totalDrivenKmValue: 10.0,
    rideStats: RideStatisticsEntity(
      totalRides: 1,
      grossEarningsCents: 5000,
      netEarningsCents: 4000,
      totalCostsCents: 1000,
      ridesTotalKm: 5,
      ridesTotalTime: 900,
    ),
  );
}

ShiftEntity buildShift() {
  return const ShiftEntity(
    index: 1,
    localId: 1,
    remoteShiftId: 10,
    date: '10/01/2026',
    startTime: '08:00',
    endTime: '09:00',
    duration: '01:00:00',
    hasRoute: true,
  );
}

RideEntity buildRide() {
  return RideEntity(
    id: 1,
    status: 'FINISHED',
    appName: 'Uber',
    paymentMethod: null,
    createdAt: DateTime(2026, 1, 10, 8, 30),
    grossValueCents: 3200,
    date: '10/01/2026',
    time: '08:30',
    origin: 'Centro',
    destination: 'Aeroporto',
    passenger: 'Joao',
    totalKm: 5,
    totalTimeSeconds: 1200,
    durationMinutes: 20,
    gainPerKmCents: 640,
    gainPerHourCents: 9600,
  );
}
