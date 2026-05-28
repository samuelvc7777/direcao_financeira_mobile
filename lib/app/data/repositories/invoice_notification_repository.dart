import '../../domain/entities/invoice_notification_entity.dart';
import '../../domain/repositories/i_invoice_notification_repository.dart';
import '../datasources/invoice_notification_local_datasource.dart';
import '../models/invoice_notification_model.dart';

class InvoiceNotificationRepository implements IInvoiceNotificationRepository {
  const InvoiceNotificationRepository({required this.localDataSource});

  final IInvoiceNotificationLocalDataSource localDataSource;

  @override
  Future<List<InvoiceNotificationDispatchRecord>> getRecords() {
    return localDataSource.getRecords();
  }

  @override
  Future<void> saveRecord(InvoiceNotificationDispatchRecord record) {
    return saveRecords([record]);
  }

  @override
  Future<void> saveRecords(
    Iterable<InvoiceNotificationDispatchRecord> records,
  ) {
    return localDataSource.saveRecords(
      records.map(InvoiceNotificationDispatchModel.fromEntity),
    );
  }

  @override
  Future<void> removeRecordsByKeys(Iterable<String> dedupeKeys) {
    return localDataSource.removeRecordsByKeys(dedupeKeys);
  }

  @override
  Future<void> cleanupBefore(DateTime cutoffDate) {
    return localDataSource.cleanupBefore(cutoffDate);
  }
}
