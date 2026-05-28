import 'dart:io';

import 'package:direcao_financeira_mobile/app/data/datasources/invoice_notification_local_datasource.dart';
import 'package:direcao_financeira_mobile/app/data/models/invoice_notification_model.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/invoice_notification_entity.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  const storageName = 'invoice_notification_local_datasource_test';
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          return Directory.systemTemp.path;
        });
    await GetStorage.init(storageName);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  setUp(() async {
    await GetStorage(storageName).erase();
  });

  test('salva e remove registros por dedupeKey', () async {
    final dataSource = InvoiceNotificationLocalDataSource(
      storage: GetStorage(storageName),
    );
    final record = _record('key-1');

    await dataSource.saveRecords([record]);
    expect(await dataSource.getRecords(), hasLength(1));

    await dataSource.removeRecordsByKeys(['key-1']);
    expect(await dataSource.getRecords(), isEmpty);
  });
}

InvoiceNotificationDispatchModel _record(String key) {
  return InvoiceNotificationDispatchModel(
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
