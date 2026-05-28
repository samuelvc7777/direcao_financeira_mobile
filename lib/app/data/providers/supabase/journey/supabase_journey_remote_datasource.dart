import '../../../datasources/i_journey_datasource.dart';
import '../../../../domain/entities/paged_result_entity.dart';
import '../../../models/active_shift_model.dart';
import '../../../models/journey_statistics_model.dart';
import '../../../models/pending_finished_shift_model.dart';
import '../../../models/shift_model.dart';
import '../../../models/shift_route_model.dart';
import '../../../shared/journey_datetime_parser.dart';
import '../shared/supabase_table_names.dart';
import '../shared/supabase_time_filter.dart';
import '../shared/supabase_user_scope.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseJourneyRemoteDataSource implements IJourneyDataSource {
  SupabaseJourneyRemoteDataSource({required this.client})
    : userScope = SupabaseUserScope(client: client);

  final SupabaseClient client;
  final SupabaseUserScope userScope;

  @override
  Future<ActiveShiftModel?> getActiveShift() async {
    final userId = await userScope.getCurrentUserId();
    final rows = await client
        .from(SupabaseTableNames.shifts)
        .select()
        .eq('userId', userId)
        .order('startTime', ascending: false);

    Map<String, dynamic>? activeRow;
    for (final row in rows as List) {
      final normalized = Map<String, dynamic>.from(row as Map);
      if (normalized['endTime'] == null) {
        activeRow = normalized;
        break;
      }
    }
    if (activeRow == null) {
      return null;
    }

    final route = await client
        .from(SupabaseTableNames.shiftRoutes)
        .select()
        .eq('shiftId', activeRow['id'])
        .maybeSingle();

    return ActiveShiftModel.fromJson({
      'id': activeRow['id'],
      'remoteShiftId': activeRow['id'],
      'startTime': activeRow['startTime'],
      'createdAt': activeRow['createdAt'] ?? activeRow['startTime'],
      'currentDrivenKm':
          ((route?['totalDistanceMeters'] as num?)?.toDouble() ?? 0) / 1000,
      'idleTime': activeRow['idleTime'] ?? 0,
      'pausedAt': activeRow['pausedAt'],
    });
  }

  @override
  Future<JourneyStatisticsModel> getDailyStatistics({
    String filter = 'day',
    String? date,
    String? endDate,
  }) async {
    final userId = await userScope.getCurrentUserId();
    final range = SupabaseTimeFilter.resolve(
      filter: filter,
      date: date,
      endDate: endDate,
    );

    final shiftRows = await _loadShiftRows(userId, range);
    final rideRows = await _loadRideRows(userId, range);

    final totalShifts = shiftRows.length;
    var totalShiftSeconds = 0;
    var totalDrivenKm = 0.0;

    for (final shift in shiftRows) {
      final start = parseJourneyDateTimeToLocal(shift['startTime'] as String);
      final end = shift['endTime'] != null
          ? parseJourneyDateTimeToLocal(shift['endTime'] as String)
          : DateTime.now();
      final totalSeconds = end.difference(start).inSeconds;

      totalShiftSeconds += totalSeconds < 0 ? 0 : totalSeconds;
      totalDrivenKm += (shift['totalDrivenKm'] as num?)?.toDouble() ?? 0.0;
    }

    final totalRides = rideRows.length;
    var grossEarningsCents = 0;
    var netEarningsCents = 0;
    var ridesTotalKm = 0.0;
    var ridesTotalTime = 0;

    for (final ride in rideRows) {
      grossEarningsCents += ride['grossValueCents'] as int? ?? 0;
      netEarningsCents += ride['netProfitCents'] as int? ?? 0;
      ridesTotalKm += (ride['totalKm'] as num?)?.toDouble() ?? 0.0;
      ridesTotalTime += ride['totalTime'] as int? ?? 0;
    }

    final averageSeconds = totalShifts == 0
        ? 0
        : (totalShiftSeconds / totalShifts).round();
    return JourneyStatisticsModel(
      totalShifts: totalShifts,
      totalTime: _formatDuration(totalShiftSeconds),
      averageTime: _formatDuration(averageSeconds),
      drivenKm: '${totalDrivenKm.toStringAsFixed(1)} km',
      totalDrivenKmValue: totalDrivenKm,
      rideStats: RideStatisticsModel(
        totalRides: totalRides,
        grossEarningsCents: grossEarningsCents,
        netEarningsCents: netEarningsCents,
        totalCostsCents: grossEarningsCents - netEarningsCents,
        ridesTotalKm: ridesTotalKm,
        ridesTotalTime: ridesTotalTime,
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
    final userId = await userScope.getCurrentUserId();
    final range = SupabaseTimeFilter.resolve(
      filter: filter,
      date: date,
      endDate: endDate,
    );
    debugPrint(
      '[SupabaseJourneyRemoteDataSource] getShiftHistory: '
      'filter=$filter date=$date endDate=$endDate '
      'localRange=${range.start}..${range.endExclusive} '
      'utcRange=${range.start.toUtc().toIso8601String()}..${range.endExclusive.toUtc().toIso8601String()} '
      'offset=$offset limit=$limit.',
    );
    final page = await _loadShiftPage(
      userId,
      range,
      offset: offset,
      limit: limit,
    );
    final rows = page.rows;
    debugPrint(
      '[SupabaseJourneyRemoteDataSource] getShiftHistory retornou: '
      'rows=${rows.length} total=${page.totalCount} '
      'ids=${rows.map((row) => row['id']).toList()} '
      'starts=${rows.map((row) => row['startTime']).toList()}.',
    );

    final shiftIds = rows.map((row) => row['id'] as int).toList();
    final routesByShiftId = <int, Map<String, dynamic>>{};
    if (shiftIds.isNotEmpty) {
      final routeRows = await client
          .from(SupabaseTableNames.shiftRoutes)
          .select()
          .inFilter('shiftId', shiftIds);
      for (final route in routeRows as List) {
        final row = Map<String, dynamic>.from(route as Map);
        routesByShiftId[row['shiftId'] as int] = row;
      }
    }

    final items = rows.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final row = entry.value;
      final start = parseJourneyDateTimeToLocal(row['startTime'] as String);
      final end = row['endTime'] != null
          ? parseJourneyDateTimeToLocal(row['endTime'] as String)
          : DateTime.now();
      final route = routesByShiftId[row['id'] as int];
      final trackedDistanceKm =
          ((route?['totalDistanceMeters'] as num?)?.toDouble() ?? 0) / 1000;
      final totalDrivenKm = (row['totalDrivenKm'] as num?)?.toDouble() ?? 0.0;

      return ShiftModel(
        index: index,
        remoteShiftId: row['id'] as int?,
        date: _formatDateOnly(start),
        startTime: _formatTimeOnly(start),
        endTime: _formatTimeOnly(end),
        duration: _formatDuration(end.difference(start).inSeconds),
        drivenKm: trackedDistanceKm > 0
            ? trackedDistanceKm.toStringAsFixed(1)
            : totalDrivenKm > 0
            ? totalDrivenKm.toStringAsFixed(1)
            : null,
        hasRoute: route != null,
        trackedDistanceKm: trackedDistanceKm,
        routePointCount: route?['pointCount'] as int? ?? 0,
      );
    }).toList();

    return PagedResultEntity<ShiftModel>(
      items: items,
      totalCount: page.totalCount,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<int> syncFinishedShift(
    PendingFinishedShiftModel shift,
    ShiftRouteModel? trackedRoute,
  ) async {
    final userId = await userScope.getCurrentUserId();
    final updatedAt = shift.endTime.toUtc().toIso8601String();
    final totalSeconds = shift.endTime.difference(shift.startTime).inSeconds;
    final safeTotalSeconds = totalSeconds < 0 ? 0 : totalSeconds;

    final payload = {
      'userId': userId,
      'startTime': shift.startTime.toUtc().toIso8601String(),
      'endTime': shift.endTime.toUtc().toIso8601String(),
      'totalTime': safeTotalSeconds,
      'averageTime': safeTotalSeconds,
      'totalDrivenKm': shift.totalDrivenKm,
      'createdAt': shift.createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt,
    };
    debugPrint(
      '[SupabaseJourneyRemoteDataSource] syncFinishedShift payload=$payload',
    );

    late final Map<String, dynamic> inserted;
    try {
      inserted = await client
          .from(SupabaseTableNames.shifts)
          .insert(payload)
          .select()
          .single();
    } on PostgrestException catch (error) {
      debugPrint(
        '[SupabaseJourneyRemoteDataSource] Erro syncFinishedShift: '
        'code=${error.code} message=${error.message} details=${error.details} hint=${error.hint}',
      );
      rethrow;
    }

    final remoteShiftId = inserted['id'] as int;
    debugPrint(
      '[SupabaseJourneyRemoteDataSource] syncFinishedShift inserido id=$remoteShiftId.',
    );

    if (trackedRoute != null) {
      await client.from(SupabaseTableNames.shiftRoutes).insert({
        'shiftId': remoteShiftId,
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
        'pointCount': trackedRoute.pointCount,
        'totalDistanceMeters': trackedRoute.totalDistanceMeters,
        'startedAt': trackedRoute.startedAt.toUtc().toIso8601String(),
        'endedAt': trackedRoute.endedAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt,
      });
    }

    return remoteShiftId;
  }

  @override
  Future<void> deleteShift(int shiftId) async {
    final userId = await userScope.getCurrentUserId();
    await client
        .from(SupabaseTableNames.shiftRoutes)
        .delete()
        .eq('shiftId', shiftId);
    await client
        .from(SupabaseTableNames.shifts)
        .delete()
        .eq('id', shiftId)
        .eq('userId', userId);
  }

  @override
  Future<ShiftRouteModel> getShiftRoute(int shiftId) async {
    final row = await client
        .from(SupabaseTableNames.shiftRoutes)
        .select()
        .eq('shiftId', shiftId)
        .single();

    return ShiftRouteModel.fromRemoteJson(Map<String, dynamic>.from(row));
  }

  Future<List<Map<String, dynamic>>> _loadShiftRows(
    int userId,
    SupabaseTimeRange range,
  ) async {
    final rows = await client
        .from(SupabaseTableNames.shifts)
        .select()
        .eq('userId', userId)
        .not('endTime', 'is', null)
        .gte('startTime', range.start.toUtc().toIso8601String())
        .lt('startTime', range.endExclusive.toUtc().toIso8601String())
        .order('startTime', ascending: false);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<({List<Map<String, dynamic>> rows, int totalCount})> _loadShiftPage(
    int userId,
    SupabaseTimeRange range, {
    required int offset,
    required int limit,
  }) async {
    if (limit <= 0) {
      final countResponse = await client
          .from(SupabaseTableNames.shifts)
          .select()
          .eq('userId', userId)
          .not('endTime', 'is', null)
          .gte('startTime', range.start.toUtc().toIso8601String())
          .lt('startTime', range.endExclusive.toUtc().toIso8601String())
          .count(CountOption.exact);
      return (
        rows: const <Map<String, dynamic>>[],
        totalCount: countResponse.count,
      );
    }

    final response = await client
        .from(SupabaseTableNames.shifts)
        .select()
        .eq('userId', userId)
        .not('endTime', 'is', null)
        .gte('startTime', range.start.toUtc().toIso8601String())
        .lt('startTime', range.endExclusive.toUtc().toIso8601String())
        .order('startTime', ascending: false)
        .range(offset, offset + limit - 1)
        .count(CountOption.exact);

    return (
      rows: response.data
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      totalCount: response.count,
    );
  }

  Future<List<Map<String, dynamic>>> _loadRideRows(
    int userId,
    SupabaseTimeRange range,
  ) async {
    final rows = await client
        .from(SupabaseTableNames.rides)
        .select()
        .eq('userId', userId)
        .eq('status', 'FINISHED')
        .gte('createdAt', _formatLocalTimestamp(range.start))
        .lt('createdAt', _formatLocalTimestamp(range.endExclusive))
        .order('createdAt', ascending: false);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  String _formatDuration(int totalSeconds) {
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final hours = safeSeconds ~/ 3600;
    final minutes = (safeSeconds % 3600) ~/ 60;
    final seconds = safeSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTimeOnly(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateOnly(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  String _formatLocalTimestamp(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    String three(int number) => number.toString().padLeft(3, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}T'
        '${two(local.hour)}:${two(local.minute)}:${two(local.second)}.'
        '${three(local.millisecond)}';
  }
}
