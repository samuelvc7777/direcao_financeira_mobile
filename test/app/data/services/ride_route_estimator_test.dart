import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:direcao_financeira_mobile/app/data/services/ride_route_estimator.dart';

void main() {
  test('usa somente Google Maps para estimar rota', () async {
    final calledHosts = <String>[];
    final dio = _fakeDio((options, handler) {
      calledHosts.add(options.uri.host);

      if (options.uri.host == 'routes.googleapis.com') {
        handler.resolve(
          Response(
            requestOptions: options,
            data: {
              'routes': [
                {'distanceMeters': 7420, 'duration': '960s'},
              ],
            },
          ),
        );
        return;
      }

      handler.reject(
        DioException(requestOptions: options, message: 'endpoint inesperado'),
      );
    });

    final estimator = RideRouteEstimator(dio: dio, googleMapsApiKey: 'gmaps');

    final estimate = await estimator.estimate(
      originAddress: 'R. Teste, 10',
      destinationAddress: 'Av. Destino, 20',
    );

    expect(calledHosts, everyElement('routes.googleapis.com'));
    expect(estimate?.distanceKm, 7.42);
    expect(estimate?.durationMinutes, 16);
    expect(estimate?.provider, 'Google Maps');
  });

  test('nao estima rota quando chave do Google Maps esta ausente', () async {
    final calledHosts = <String>[];
    final dio = _fakeDio((options, handler) {
      calledHosts.add(options.uri.host);
      handler.reject(
        DioException(requestOptions: options, message: 'endpoint inesperado'),
      );
    });

    final estimator = RideRouteEstimator(dio: dio);

    final estimate = await estimator.estimate(
      originAddress: 'R. Teste, 10',
      destinationAddress: 'Av. Destino, 20',
    );

    expect(calledHosts, isEmpty);
    expect(estimate, isNull);
  });
}

Dio _fakeDio(
  void Function(RequestOptions options, RequestInterceptorHandler handler)
  onRequest,
) {
  final dio = Dio();
  dio.interceptors.add(InterceptorsWrapper(onRequest: onRequest));
  return dio;
}
