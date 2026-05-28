import 'package:dio/dio.dart';

import '../../../datasources/i_ride_datasource.dart';
import '../../../../domain/entities/detected_ride_draft_entity.dart';
import '../../../../domain/entities/paged_result_entity.dart';
import '../../../models/ride_model.dart';

class NestRideRemoteDataSource implements IRideDataSource {
  NestRideRemoteDataSource({required this.dio});

  final Dio dio;

  @override
  Future<PagedResultEntity<RideModel>> getRides({
    String period = 'day',
    String? date,
    String? endDate,
    String? status,
    int offset = 0,
    int limit = 20,
  }) async {
    final response = await dio.get(
      '/rides',
      queryParameters: {
        'period': period,
        'date': date,
        'endDate': endDate,
        'status': status,
      },
    );

    final data = response.data;
    if (data is! List) {
      return PagedResultEntity<RideModel>(
        items: const [],
        totalCount: 0,
        offset: offset,
        limit: limit,
      );
    }

    final rides = data
        .whereType<Map>()
        .map((json) => RideModel.fromJson(Map<String, dynamic>.from(json)))
        .where((ride) {
          if (status == null || status.isEmpty) {
            return true;
          }
          if (status == 'CANCELED') {
            return ride.status == 'CANCELED' || ride.status == 'CANCELLED';
          }
          return ride.status == status;
        })
        .toList();

    final safeOffset = offset.clamp(0, rides.length);
    final safeEnd = (safeOffset + limit).clamp(0, rides.length);

    return PagedResultEntity<RideModel>(
      items: rides.sublist(safeOffset, safeEnd),
      totalCount: rides.length,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<void> createDetectedRide(DetectedRideDraftEntity ride) {
    throw UnsupportedError(
      'Criacao de corrida pendente via overlay esta disponivel apenas no provider Supabase.',
    );
  }

  @override
  Future<void> createRideWithStatus({
    required DetectedRideDraftEntity ride,
    required String status,
    String? paymentMethod,
    String? cancelReason,
  }) {
    throw UnsupportedError(
      'Persistencia remota de corrida detectada esta disponivel apenas no provider Supabase.',
    );
  }

  @override
  Future<void> updateFinishedRide({
    required int rideId,
    required DetectedRideDraftEntity ride,
  }) {
    throw UnsupportedError(
      'Atualizacao de corrida finalizada esta disponivel apenas no provider Supabase.',
    );
  }

  @override
  Future<void> finishRide({
    required int rideId,
    required String paymentMethod,
  }) {
    throw UnsupportedError(
      'Finalizacao de corrida via detalhes esta disponivel apenas no provider Supabase.',
    );
  }

  @override
  Future<void> cancelRide({required int rideId, required String cancelReason}) {
    throw UnsupportedError(
      'Cancelamento de corrida via detalhes esta disponivel apenas no provider Supabase.',
    );
  }

  @override
  Future<void> deleteRide({required int rideId}) {
    throw UnsupportedError(
      'Exclusao de corrida esta disponivel apenas no provider Supabase.',
    );
  }
}
