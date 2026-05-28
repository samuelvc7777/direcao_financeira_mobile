import 'package:direcao_financeira_mobile/app/data/models/pending_finished_shift_model.dart';
import 'package:direcao_financeira_mobile/app/data/models/tracked_route_point_model.dart';
import 'package:direcao_financeira_mobile/app/data/models/shift_route_model.dart';
import 'package:direcao_financeira_mobile/app/data/shared/journey_datetime_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parser trata timestamp sem fuso como UTC e converte para local', () {
    final parsed = parseJourneyDateTimeToLocal('2026-05-18T10:00:00');
    expect(parsed, DateTime.utc(2026, 5, 18, 10).toLocal());
  });

  test('turno pendente preserva horario local ao desserializar', () {
    final model = PendingFinishedShiftModel.fromJson({
      'localId': 1,
      'remoteShiftId': null,
      'startTime': '2026-05-18T10:00:00',
      'endTime': '2026-05-18T12:30:00',
      'createdAt': '2026-05-18T12:30:00',
      'idleTimeSeconds': 0,
      'totalDrivenKm': 12.5,
    });

    expect(model.startTime, DateTime.utc(2026, 5, 18, 10).toLocal());
    expect(model.endTime, DateTime.utc(2026, 5, 18, 12, 30).toLocal());
  });

  test('rota do turno preserva horario local ao desserializar', () {
    final model = ShiftRouteModel.fromRemoteJson({
      'shiftId': 7,
      'startedAt': '2026-05-18T10:00:00',
      'endedAt': '2026-05-18T12:30:00',
      'totalDistanceMeters': 1000,
      'pointCount': 0,
      'points': [],
    });

    expect(model.startedAt, DateTime.utc(2026, 5, 18, 10).toLocal());
    expect(model.endedAt, DateTime.utc(2026, 5, 18, 12, 30).toLocal());
  });

  test('ponto de rota preserva horario local ao desserializar', () {
    final model = TrackedRoutePointModel.fromJson({
      'latitude': -23.5,
      'longitude': -46.6,
      'accuracyMeters': 10,
      'recordedAt': '2026-05-18T10:15:00',
    });

    expect(model.recordedAt, DateTime.utc(2026, 5, 18, 10, 15).toLocal());
  });
}
