import 'package:get_storage/get_storage.dart';

import '../models/invoice_notification_model.dart';

abstract class IInvoiceNotificationLocalDataSource {
  Future<List<InvoiceNotificationDispatchModel>> getRecords();

  Future<void> saveRecords(Iterable<InvoiceNotificationDispatchModel> records);

  Future<void> removeRecordsByKeys(Iterable<String> dedupeKeys);

  Future<void> cleanupBefore(DateTime cutoffDate);
}

class InvoiceNotificationLocalDataSource
    implements IInvoiceNotificationLocalDataSource {
  InvoiceNotificationLocalDataSource({required this.storage});

  static const _storageKey = 'invoice_notification_dispatch_records';

  final GetStorage storage;

  @override
  Future<List<InvoiceNotificationDispatchModel>> getRecords() async {
    final rawRecords = storage.read<List<dynamic>>(_storageKey) ?? const [];
    return rawRecords.whereType<Map>().map((json) {
      return InvoiceNotificationDispatchModel.fromJson(
        Map<String, dynamic>.from(json),
      );
    }).toList();
  }

  @override
  Future<void> saveRecords(
    Iterable<InvoiceNotificationDispatchModel> records,
  ) async {
    final merged = {
      for (final record in await getRecords()) record.dedupeKey: record,
      for (final record in records) record.dedupeKey: record,
    }.values.toList();

    await _write(merged);
  }

  @override
  Future<void> removeRecordsByKeys(Iterable<String> dedupeKeys) async {
    final keys = dedupeKeys.toSet();
    final remaining = (await getRecords())
        .where((record) => !keys.contains(record.dedupeKey))
        .toList();
    await _write(remaining);
  }

  @override
  Future<void> cleanupBefore(DateTime cutoffDate) async {
    final cutoff = DateTime(cutoffDate.year, cutoffDate.month, cutoffDate.day);
    final remaining = (await getRecords()).where((record) {
      final eventDate = DateTime(
        record.eventDate.year,
        record.eventDate.month,
        record.eventDate.day,
      );
      return !eventDate.isBefore(cutoff);
    }).toList();
    await _write(remaining);
  }

  Future<void> _write(
    Iterable<InvoiceNotificationDispatchModel> records,
  ) async {
    await storage.write(
      _storageKey,
      records.map((record) => record.toJson()).toList(),
    );
  }
}
