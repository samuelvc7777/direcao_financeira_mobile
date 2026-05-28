import 'package:direcao_financeira_mobile/app/data/datasources/invoice_notification_local_datasource.dart';
import 'package:direcao_financeira_mobile/app/data/models/invoice_notification_model.dart';
import 'package:direcao_financeira_mobile/app/data/repositories/invoice_notification_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/invoice_notification_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('delegates save/get para o datasource local', () async {
    final dataSource = _FakeLocalDataSource();
    final repository = InvoiceNotificationRepository(
      localDataSource: dataSource,
    );

    await repository.saveRecord(_record('key-1'));

    expect(await repository.getRecords(), hasLength(1));
  });
}

class _FakeLocalDataSource implements IInvoiceNotificationLocalDataSource {
  final records = <InvoiceNotificationDispatchModel>[];

  @override
  Future<void> cleanupBefore(DateTime cutoffDate) async {}

  @override
  Future<List<InvoiceNotificationDispatchModel>> getRecords() async => records;

  @override
  Future<void> removeRecordsByKeys(Iterable<String> dedupeKeys) async {}

  @override
  Future<void> saveRecords(
    Iterable<InvoiceNotificationDispatchModel> records,
  ) async {
    this.records.addAll(records);
  }
}

InvoiceNotificationDispatchRecord _record(String key) {
  return InvoiceNotificationDispatchRecord(
    dedupeKey: key,
    notificationId: 1,
    cardId: 1,
    type: InvoiceNotificationType.overdue,
    eventDate: DateTime(2026, 5, 26),
    scheduledAt: DateTime(2026, 5, 26, 10),
    status: InvoiceNotificationDispatchStatus.scheduled,
    updatedAt: DateTime(2026, 5, 26, 9),
  );
}
