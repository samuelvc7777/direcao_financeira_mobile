import '../../domain/entities/invoice_notification_entity.dart';

abstract class InvoiceNotificationScheduler {
  Future<void> initialize();

  Future<void> schedule(InvoiceNotificationCandidate candidate);

  Future<void> cancel(int notificationId);

  Future<void> cancelMany(Iterable<int> notificationIds) async {
    for (final notificationId in notificationIds) {
      await cancel(notificationId);
    }
  }
}
