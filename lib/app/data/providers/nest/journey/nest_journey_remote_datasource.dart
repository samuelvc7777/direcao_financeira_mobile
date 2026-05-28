import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../datasources/i_journey_datasource.dart';
import '../../../../domain/entities/paged_result_entity.dart';
import '../../../models/active_shift_model.dart';
import '../../../models/journey_statistics_model.dart';
import '../../../models/pending_finished_shift_model.dart';
import '../../../models/shift_model.dart';
import '../../../models/shift_route_model.dart';
import '../../../shared/journey_datetime_parser.dart';

class NestJourneyRemoteDataSource implements IJourneyDataSource {
  NestJourneyRemoteDataSource({required this.dio});

  final Dio dio;

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 0) {
      return '00:00:00';
    }

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTimeOnly(String dateString) {
    try {
      final date = parseJourneyDateTimeToLocal(dateString);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--:--';
    }
  }

  String _formatDateOnly(String dateString) {
    try {
      final date = parseJourneyDateTimeToLocal(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return '--/--/----';
    }
  }

  @override
  Future<ActiveShiftModel?> getActiveShift() async {
    final response = await dio.get('/journey/active');
    final rawData = response.data;

    if (rawData == null) {
      return null;
    }

    if (rawData is String) {
      final normalized = rawData.trim();
      if (normalized.isEmpty || normalized == 'null') {
        return null;
      }

      final decoded = jsonDecode(normalized);
      if (decoded is Map) {
        return ActiveShiftModel.fromJson(Map<String, dynamic>.from(decoded));
      }

      throw const FormatException('Resposta invalida ao carregar turno ativo.');
    }

    if (rawData is Map) {
      return ActiveShiftModel.fromJson(Map<String, dynamic>.from(rawData));
    }

    throw const FormatException('Resposta invalida ao carregar turno ativo.');
  }

  @override
  Future<JourneyStatisticsModel> getDailyStatistics({
    String filter = 'day',
    String? date,
    String? endDate,
  }) async {
    final response = await dio.get(
      '/journey/stats',
      queryParameters: {'filter': filter, 'date': date, 'endDate': endDate},
    );
    final data = response.data;

    return JourneyStatisticsModel(
      totalDrivenKmValue: 0,
      totalShifts: data['totalShifts'] ?? 0,
      totalTime: _formatDuration(data['totalTime'] ?? 0),
      averageTime: _formatDuration(data['avgShiftTime'] ?? 0),
      drivenKm: '${(data['totalKm'] ?? 0.0).toStringAsFixed(1)} km',
      rideStats: data['rideStats'] != null
          ? RideStatisticsModel.fromJson(
              Map<String, dynamic>.from(data['rideStats'] as Map),
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

  @override
  Future<PagedResultEntity<ShiftModel>> getShiftHistory({
    String filter = 'day',
    String? date,
    String? endDate,
    int offset = 0,
    int limit = 20,
  }) async {
    final response = await dio.get(
      '/journey/history',
      queryParameters: {'filter': filter, 'date': date, 'endDate': endDate},
    );
    final data = response.data;

    if (data is! List) {
      return PagedResultEntity<ShiftModel>(
        items: const [],
        totalCount: 0,
        offset: offset,
        limit: limit,
      );
    }

    final shifts = <ShiftModel>[];
    var index = 1;

    for (final item in data.whereType<Map>()) {
      final json = Map<String, dynamic>.from(item);
      final startTimeStr = json['startTime'] as String?;
      final endTimeStr = json['endTime'] as String?;
      final totalTime = json['totalTime'] as int? ?? 0;
      final totalDrivenKm = json['totalDrivenKm'] as num? ?? 0.0;
      final trackedDistanceKm =
          (json['trackedDistanceKm'] as num?)?.toDouble() ?? 0.0;
      final hasRoute = json['hasRoute'] == true;

      shifts.add(
        ShiftModel(
          index: index++,
          remoteShiftId: json['remoteShiftId'] as int? ?? json['id'] as int?,
          date: startTimeStr != null
              ? _formatDateOnly(startTimeStr)
              : '--/--/----',
          startTime: startTimeStr != null
              ? _formatTimeOnly(startTimeStr)
              : '--:--',
          endTime: endTimeStr != null ? _formatTimeOnly(endTimeStr) : '--:--',
          duration: _formatDuration(totalTime),
          drivenKm: hasRoute
              ? trackedDistanceKm.toStringAsFixed(1)
              : totalDrivenKm > 0
              ? totalDrivenKm.toStringAsFixed(1)
              : null,
          hasRoute: hasRoute,
          trackedDistanceKm: trackedDistanceKm,
          routePointCount: json['routePointCount'] as int? ?? 0,
        ),
      );
    }

    final safeOffset = offset.clamp(0, shifts.length);
    final safeEnd = (safeOffset + limit).clamp(0, shifts.length);

    return PagedResultEntity<ShiftModel>(
      items: shifts.sublist(safeOffset, safeEnd),
      totalCount: shifts.length,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<int> syncFinishedShift(
    PendingFinishedShiftModel shift,
    ShiftRouteModel? trackedRoute,
  ) async {
    final payload = {
      'startTime': shift.startTime.toUtc().toIso8601String(),
      'endTime': shift.endTime.toUtc().toIso8601String(),
      'totalDrivenKm': shift.totalDrivenKm,
      if (shift.remoteShiftId != null) 'remoteShiftId': shift.remoteShiftId,
      if (trackedRoute != null)
        'trackedRoute': {
          'points': trackedRoute.points
              .map(
                (point) => {
                  'latitude': point.latitude,
                  'longitude': point.longitude,
                  'accuracyMeters': point.accuracyMeters,
                  'recordedAt': point.recordedAt.toUtc().toIso8601String(),
                },
              )
              .toList(),
          'totalDistanceMeters': trackedRoute.totalDistanceMeters,
          'startedAt': trackedRoute.startedAt.toUtc().toIso8601String(),
          'endedAt': trackedRoute.endedAt.toUtc().toIso8601String(),
        },
    };

    final response = await dio.post('/journey/sync-finished', data: payload);

    final data = response.data;
    if (data is Map) {
      return data['id'] as int;
    }

    throw const FormatException('Resposta invalida ao sincronizar turno.');
  }

  @override
  Future<void> deleteShift(int shiftId) async {
    await dio.delete('/journey/$shiftId');
  }

  @override
  Future<ShiftRouteModel> getShiftRoute(int shiftId) async {
    final response = await dio.get('/journey/$shiftId/route');
    final data = response.data;

    if (data is Map) {
      return ShiftRouteModel.fromRemoteJson(Map<String, dynamic>.from(data));
    }

    throw const FormatException('Resposta invalida ao carregar rota do turno.');
  }
}
