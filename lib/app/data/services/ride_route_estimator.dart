import 'package:dio/dio.dart';

class RideRouteEstimate {
  const RideRouteEstimate({
    required this.distanceKm,
    required this.durationMinutes,
    required this.provider,
  });

  final double distanceKm;
  final int durationMinutes;
  final String provider;
}

class RideRouteEstimator {
  RideRouteEstimator({Dio? dio, String? googleMapsApiKey})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 5),
              headers: const {
                'User-Agent': 'DirecaoFinanceira/1.0 ride import',
              },
            ),
          ),
      _googleMapsApiKey = googleMapsApiKey?.trim() ?? '';

  final Dio _dio;
  final String _googleMapsApiKey;

  Future<RideRouteEstimate?> estimate({
    required String originAddress,
    required String destinationAddress,
  }) async {
    return _estimateWithGoogleDirections(
      originAddress: originAddress,
      destinationAddress: destinationAddress,
    );
  }

  Future<RideRouteEstimate?> _estimateWithGoogleDirections({
    required String originAddress,
    required String destinationAddress,
  }) async {
    if (_googleMapsApiKey.isEmpty) {
      return null;
    }

    final originQueries = _googleRouteQueries(originAddress);
    final destinationQueries = _googleRouteQueries(destinationAddress);

    for (final origin in originQueries) {
      for (final destination in destinationQueries) {
        Response<Map<String, dynamic>> response;
        try {
          response = await _dio.post<Map<String, dynamic>>(
            'https://routes.googleapis.com/directions/v2:computeRoutes',
            options: Options(
              headers: {
                'X-Goog-Api-Key': _googleMapsApiKey,
                'X-Goog-FieldMask': 'routes.distanceMeters,routes.duration',
              },
            ),
            data: {
              'origin': {'address': origin},
              'destination': {'address': destination},
              'travelMode': 'DRIVE',
              'languageCode': 'pt-BR',
              'regionCode': 'BR',
            },
          );
        } on DioException {
          continue;
        } catch (_) {
          continue;
        }

        final routes = response.data?['routes'];
        if (routes is! List || routes.isEmpty || routes.first is! Map) {
          continue;
        }

        final route = Map<String, dynamic>.from(routes.first as Map);
        final estimate = _estimateFromMetersAndSeconds(
          distanceMeters: (route['distanceMeters'] as num?)?.toDouble(),
          durationSeconds: _googleDurationSeconds(route['duration']),
          provider: 'Google Maps',
        );
        if (estimate != null) {
          return estimate;
        }
      }
    }

    return null;
  }

  RideRouteEstimate? _estimateFromMetersAndSeconds({
    required double? distanceMeters,
    required double? durationSeconds,
    required String provider,
  }) {
    if (distanceMeters == null || durationSeconds == null) {
      return null;
    }

    return RideRouteEstimate(
      distanceKm: distanceMeters / 1000,
      durationMinutes: (durationSeconds / 60).round().clamp(1, 9999),
      provider: provider,
    );
  }

  String _googleAddressQuery(String address) {
    final normalized = _normalizeAddress(address);
    if (normalized.toLowerCase().contains('brasil')) {
      return normalized;
    }

    return '$normalized, Sao Joao del Rei, MG, Brasil';
  }

  List<String> _googleRouteQueries(String address) {
    final normalized = _normalizeAddress(address);
    final streetCandidate = _extractStreetCandidate(normalized);
    final establishmentCandidate = normalized
        .split(RegExp(r'\s+-\s+'))
        .first
        .trim();

    return <String>[
      _googleAddressQuery(normalized),
      _googleAddressQuery(streetCandidate),
      _googleAddressQuery(establishmentCandidate),
    ].where((query) => query.isNotEmpty).toSet().toList();
  }

  String _extractStreetCandidate(String address) {
    final parts = address
        .split(RegExp(r'\s+-\s+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    final streetIndex = parts.indexWhere(
      (part) => RegExp(
        r'^(Rua|Avenida|Av\.|R\.|Travessa|Praca)\b',
        caseSensitive: false,
      ).hasMatch(part),
    );
    if (streetIndex < 0) {
      return address;
    }

    return parts.skip(streetIndex).join(', ');
  }

  double? _googleDurationSeconds(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    final normalized = value.endsWith('s')
        ? value.substring(0, value.length - 1)
        : value;
    return double.tryParse(normalized);
  }

  String _normalizeAddress(String address) {
    return address
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\bAv\.\s*', caseSensitive: false), 'Avenida ')
        .replaceAll(RegExp(r'\bR\.\s*', caseSensitive: false), 'Rua ')
        .replaceAll(RegExp(r'\bPca\.\s*', caseSensitive: false), 'Praca ')
        .replaceAll(RegExp(r'\bPraca\b', caseSensitive: false), 'Praca')
        .replaceAll(RegExp(r'\bSao\b', caseSensitive: false), 'Sao')
        .trim();
  }
}
