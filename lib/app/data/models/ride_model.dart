import '../../domain/entities/detected_ride_draft_entity.dart';
import '../../domain/entities/ride_entity.dart';

class RideModel extends RideEntity {
  const RideModel({
    required super.id,
    required super.status,
    required super.appName,
    required super.paymentMethod,
    required super.createdAt,
    required super.grossValueCents,
    required super.date,
    required super.time,
    required super.origin,
    required super.destination,
    super.rideType,
    required super.passenger,
    required super.totalKm,
    required super.totalTimeSeconds,
    required super.durationMinutes,
    required super.gainPerKmCents,
    required super.gainPerHourCents,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    String formattedDate = '--/--';
    String formattedTime = '--:--';

    if (json['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(json['createdAt']).toLocal();
        formattedDate =
            '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}';
        formattedTime =
            '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    final durationSeconds = json['totalTime'] as int? ?? 0;
    final platformName = (json['platformName'] as String?)?.trim();
    final originAddress = (json['originAddress'] as String?)?.trim();
    final destinationAddress = (json['destinationAddress'] as String?)?.trim();
    final rideType = (json['rideType'] as String?)?.trim();
    final passengerName = (json['passengerName'] as String?)?.trim();

    return RideModel(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'PENDING',
      appName: platformName != null && platformName.isNotEmpty
          ? platformName
          : 'App',
      paymentMethod: json['paymentMethod'] as String?,
      createdAt: createdAt,
      grossValueCents: json['grossValueCents'] as int? ?? 0,
      date: formattedDate,
      time: formattedTime,
      origin: originAddress?.isNotEmpty == true
          ? originAddress!
          : 'Origem nao informada',
      destination: destinationAddress?.isNotEmpty == true
          ? destinationAddress!
          : 'Destino nao informado',
      rideType: rideType?.isNotEmpty == true ? rideType : null,
      passenger: passengerName?.isNotEmpty == true
          ? passengerName!
          : 'Nao informado',
      totalKm: (json['totalKm'] as num?)?.toDouble() ?? 0,
      totalTimeSeconds: durationSeconds,
      durationMinutes: durationSeconds ~/ 60,
      gainPerKmCents: json['gainPerKmCents'] as int? ?? 0,
      gainPerHourCents: json['gainPerHourCents'] as int? ?? 0,
    );
  }

  factory RideModel.fromDetectedRideDraft({
    required int localId,
    required DateTime createdAt,
    required DetectedRideDraftEntity draft,
  }) {
    final localDate = createdAt.toLocal();

    return RideModel(
      id: localId,
      status: 'PENDING',
      appName: (draft.platformName?.trim().isNotEmpty ?? false)
          ? draft.platformName!.trim()
          : 'App',
      paymentMethod: draft.paymentMethod,
      createdAt: localDate,
      grossValueCents: draft.grossValueCents,
      date:
          '${localDate.day.toString().padLeft(2, '0')}/${localDate.month.toString().padLeft(2, '0')}',
      time:
          '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}',
      origin: draft.originAddress ?? 'Origem nao informada',
      destination: draft.destinationAddress ?? 'Destino nao informado',
      rideType: draft.rideType,
      passenger: draft.passengerName ?? 'Nao informado',
      totalKm: draft.totalKm,
      totalTimeSeconds: draft.totalTimeSeconds,
      durationMinutes: draft.totalTimeSeconds ~/ 60,
      gainPerKmCents: draft.gainPerKmCents,
      gainPerHourCents: draft.gainPerHourCents,
    );
  }

  Map<String, dynamic> toJson({DateTime? createdAt}) {
    final effectiveCreatedAt = createdAt ?? DateTime.now();

    return {
      'id': id,
      'status': status,
      'platformName': appName,
      'paymentMethod': paymentMethod,
      'grossValueCents': grossValueCents,
      'createdAt': effectiveCreatedAt.toUtc().toIso8601String(),
      'originAddress': origin,
      'destinationAddress': destination,
      'rideType': rideType,
      'passengerName': passenger,
      'totalKm': totalKm,
      'totalTime': totalTimeSeconds,
      'gainPerKmCents': gainPerKmCents,
      'gainPerHourCents': gainPerHourCents,
    };
  }

  DetectedRideDraftEntity toDetectedRideDraft({String? paymentMethodOverride}) {
    return DetectedRideDraftEntity(
      platformName: appName,
      detectedAt: createdAt,
      paymentMethod: paymentMethodOverride ?? paymentMethod ?? 'APP',
      grossValueCents: grossValueCents,
      netProfitCents: 0,
      totalKm: totalKm,
      totalTimeSeconds: totalTimeSeconds,
      gainPerKmCents: gainPerKmCents,
      gainPerHourCents: gainPerHourCents,
      passengerName: passenger,
      originAddress: origin,
      destinationAddress: destination,
      rideType: rideType,
    );
  }
}
