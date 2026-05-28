import '../entities/invoice_notification_entity.dart';

abstract class IInvoiceNotificationRepository {
  Future<List<InvoiceNotificationDispatchRecord>> getRecords();

  Future<void> saveRecord(InvoiceNotificationDispatchRecord record);

  Future<void> saveRecords(Iterable<InvoiceNotificationDispatchRecord> records);

  Future<void> removeRecordsByKeys(Iterable<String> dedupeKeys);

  Future<void> cleanupBefore(DateTime cutoffDate);
}
