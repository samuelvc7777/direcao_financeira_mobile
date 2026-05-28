import 'package:direcao_financeira_mobile/app/domain/entities/ride_import_batch_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/ride_import_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RideImportBatchEntity', () {
    test('encode gera marcador estruturado e parse recupera os ids', () {
      final batch = RideImportBatchEntity(
        batchId: '20260326123000',
        rideIds: [9, 2, 7],
      );

      final encoded = batch.encode();
      final parsed = RideImportBatchEntity.tryParse(
        '$kRideImportDescriptionPrefix $encoded | Corridas do turno',
      );

      expect(encoded, 'batch=20260326123000 rides=2,7,9');
      expect(parsed, isNotNull);
      expect(parsed!.batchId, '20260326123000');
      expect(parsed.rideIds, [2, 7, 9]);
    });

    test('parse ignora descricoes que nao seguem o contrato', () {
      expect(RideImportBatchEntity.tryParse('Pagamento normal'), isNull);
      expect(
        RideImportBatchEntity.tryParse(
          '[sistema] importacao_corridas: batch=abc',
        ),
        isNull,
      );
    });
  });

  group('RideImportEntity', () {
    test('isEligible respeita status, valor e forma de pagamento', () {
      final ride = RideImportEntity(
        rideId: 1,
        status: 'FINISHED',
        appName: 'Uber',
        paymentMethod: 'Cartao',
        grossValueCents: 2500,
        date: '26/03/2026',
        time: '12:30',
        isAlreadyImported: false,
      );

      expect(ride.isEligible, isTrue);
      expect(ride.copyWith(status: 'CANCELED').isEligible, isFalse);
    });
  });
}
