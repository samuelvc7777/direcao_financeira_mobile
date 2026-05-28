import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../../datasources/i_ride_datasource.dart';
import '../../../../domain/entities/detected_ride_draft_entity.dart';
import '../../../../domain/entities/paged_result_entity.dart';
import '../../../models/ride_model.dart';
import '../shared/supabase_table_names.dart';
import '../shared/supabase_time_filter.dart';
import '../shared/supabase_user_scope.dart';

class SupabaseRideRemoteDataSource implements IRideDataSource {
  SupabaseRideRemoteDataSource({required this.client})
    : userScope = SupabaseUserScope(client: client);

  final SupabaseClient client;
  final SupabaseUserScope userScope;

  @override
  Future<PagedResultEntity<RideModel>> getRides({
    String period = 'day',
    String? date,
    String? endDate,
    String? status,
    int offset = 0,
    int limit = 20,
  }) async {
    final userId = await userScope.getCurrentUserId();
    final range = SupabaseTimeFilter.resolve(
      filter: period,
      date: date,
      endDate: endDate,
    );

    final response =
        await _buildRideQuery(userId: userId, range: range, status: status)
            .order('createdAt', ascending: false)
            .range(offset, offset + limit - 1)
            .count(CountOption.exact);

    return PagedResultEntity<RideModel>(
      items: response.data
          .map(
            (row) => RideModel.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList(),
      totalCount: response.count,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<void> createDetectedRide(DetectedRideDraftEntity ride) async {
    await createRideWithStatus(ride: ride, status: 'PENDING');
  }

  @override
  Future<void> createRideWithStatus({
    required DetectedRideDraftEntity ride,
    required String status,
    String? paymentMethod,
    String? cancelReason,
  }) async {
    final userId = await userScope.getCurrentUserId();
    final createdAt = _formatLocalTimestamp(ride.detectedAt ?? DateTime.now());
    final now = DateTime.now().toUtc().toIso8601String();

    final payload = {
      'userId': userId,
      'status': status,
      'platformName': ride.platformName,
      'paymentMethod': paymentMethod ?? ride.paymentMethod,
      'grossValueCents': ride.grossValueCents,
      'netProfitCents': ride.netProfitCents,
      'totalKm': ride.totalKm,
      'totalTime': ride.totalTimeSeconds,
      'gainPerKmCents': ride.gainPerKmCents,
      'gainPerHourCents': ride.gainPerHourCents,
      'passengerName': ride.passengerName,
      'originAddress': ride.originAddress,
      'destinationAddress': ride.destinationAddress,
      'cancelReason': cancelReason,
      'createdAt': createdAt,
      'updatedAt': now,
    };

    try {
      await client.from(SupabaseTableNames.rides).insert(payload);
    } on PostgrestException catch (error) {
      debugPrint(
        '[SupabaseRideRemoteDataSource] Erro ao inserir corrida: '
        'code=${error.code} message=${error.message} details=${error.details} hint=${error.hint} payload=$payload',
      );
      rethrow;
    }
  }

  @override
  Future<void> updateFinishedRide({
    required int rideId,
    required DetectedRideDraftEntity ride,
  }) async {
    final userId = await userScope.getCurrentUserId();
    final createdAt = _formatLocalTimestamp(ride.detectedAt ?? DateTime.now());
    final now = DateTime.now().toUtc().toIso8601String();

    final payload = {
      'status': 'FINISHED',
      'platformName': ride.platformName,
      'paymentMethod': ride.paymentMethod,
      'grossValueCents': ride.grossValueCents,
      'netProfitCents': ride.netProfitCents,
      'totalKm': ride.totalKm,
      'totalTime': ride.totalTimeSeconds,
      'gainPerKmCents': ride.gainPerKmCents,
      'gainPerHourCents': ride.gainPerHourCents,
      'passengerName': ride.passengerName,
      'originAddress': ride.originAddress,
      'destinationAddress': ride.destinationAddress,
      'createdAt': createdAt,
      'updatedAt': now,
    };

    try {
      await client
          .from(SupabaseTableNames.rides)
          .update(payload)
          .eq('id', rideId)
          .eq('userId', userId);
    } on PostgrestException catch (error) {
      debugPrint(
        '[SupabaseRideRemoteDataSource] Erro ao atualizar corrida: '
        'code=${error.code} message=${error.message} details=${error.details} hint=${error.hint} payload=$payload',
      );
      rethrow;
    }
  }

  @override
  Future<void> finishRide({
    required int rideId,
    required String paymentMethod,
  }) async {
    final userId = await userScope.getCurrentUserId();
    final now = DateTime.now().toUtc().toIso8601String();

    await client
        .from(SupabaseTableNames.rides)
        .update({
          'status': 'FINISHED',
          'paymentMethod': paymentMethod,
          'updatedAt': now,
        })
        .eq('id', rideId)
        .eq('userId', userId);
  }

  @override
  Future<void> cancelRide({
    required int rideId,
    required String cancelReason,
  }) async {
    final userId = await userScope.getCurrentUserId();
    final now = DateTime.now().toUtc().toIso8601String();

    await client
        .from(SupabaseTableNames.rides)
        .update({
          'status': 'CANCELED',
          'cancelReason': cancelReason,
          'updatedAt': now,
        })
        .eq('id', rideId)
        .eq('userId', userId);
  }

  @override
  Future<void> deleteRide({required int rideId}) async {
    final userId = await userScope.getCurrentUserId();

    await client
        .from(SupabaseTableNames.rides)
        .delete()
        .eq('id', rideId)
        .eq('userId', userId);
  }

  PostgrestTransformBuilder<PostgrestList> _buildRideQuery({
    required int userId,
    required SupabaseTimeRange range,
    required String? status,
  }) {
    var query = client
        .from(SupabaseTableNames.rides)
        .select()
        .eq('userId', userId)
        .gte('createdAt', _formatLocalTimestamp(range.start))
        .lt('createdAt', _formatLocalTimestamp(range.endExclusive));

    if (status == null || status.isEmpty) {
      return query;
    }

    return query.eq('status', status);
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
