import 'package:direcao_financeira_mobile/app/domain/services/online_hourly_projection_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OnlineHourlyProjectionCalculator', () {
    test(
      'calcula media historica, corrida isolada e media projetada ponderada',
      () {
        final result = OnlineHourlyProjectionCalculator.project(
          historicalEarningsCents: 3000,
          historicalOnlineTimeSeconds: 3600,
          offeredRideEarningsCents: 1733,
          offeredRideDurationSeconds: 16 * 60,
        );

        expect(result.historicalHourlyCents, 3000);
        expect(result.offeredRideHourlyCents, 6499);
        expect(result.projectedHourlyCents, 3737);
        expect(result.hourlyDeltaCents, 737);
        expect(result.improvesHistoricalAverage, isTrue);
      },
    );

    test('nao soma taxas horarias diretamente', () {
      final result = OnlineHourlyProjectionCalculator.project(
        historicalEarningsCents: 3000,
        historicalOnlineTimeSeconds: 3600,
        offeredRideEarningsCents: 1733,
        offeredRideDurationSeconds: 16 * 60,
      );

      expect(result.projectedHourlyCents, isNot(9499));
    });

    test(
      'quando nao existe historico usa a corrida nova como base inicial',
      () {
        final result = OnlineHourlyProjectionCalculator.project(
          historicalEarningsCents: 0,
          historicalOnlineTimeSeconds: 0,
          offeredRideEarningsCents: 2094,
          offeredRideDurationSeconds: 16 * 60,
        );

        expect(result.historicalHourlyCents, 0);
        expect(result.offeredRideHourlyCents, 7853);
        expect(result.projectedHourlyCents, 7853);
        expect(result.improvesHistoricalAverage, isTrue);
      },
    );

    test(
      'quando a corrida nova nao tem tempo valido mantem a media historica',
      () {
        final result = OnlineHourlyProjectionCalculator.project(
          historicalEarningsCents: 9000,
          historicalOnlineTimeSeconds: 2 * 3600,
          offeredRideEarningsCents: 2094,
          offeredRideDurationSeconds: 0,
        );

        expect(result.historicalHourlyCents, 4500);
        expect(result.offeredRideHourlyCents, 0);
        expect(result.projectedHourlyCents, 4500);
      },
    );
  });
}
