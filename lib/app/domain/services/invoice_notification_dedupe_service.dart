import '../entities/invoice_notification_entity.dart';

class InvoiceNotificationDedupeService {
  List<InvoiceNotificationCandidate> filterPending({
    required Iterable<InvoiceNotificationCandidate> candidates,
    required Iterable<InvoiceNotificationDispatchRecord> records,
  }) {
    final activeKeys = records
        .where((record) {
          return record.status == InvoiceNotificationDispatchStatus.scheduled;
        })
        .map((record) => record.dedupeKey)
        .toSet();
    final selected = <String, InvoiceNotificationCandidate>{};

    for (final candidate in candidates) {
      if (activeKeys.contains(candidate.dedupeKey)) {
        continue;
      }

      final groupKey =
          '${candidate.cardId}:${invoiceNotificationDateKey(candidate.eventDate)}';
      final current = selected[groupKey];
      if (current == null ||
          _priority(candidate.type) > _priority(current.type)) {
        selected[groupKey] = candidate;
      }
    }

    return selected.values.toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  int _priority(InvoiceNotificationType type) {
    switch (type) {
      case InvoiceNotificationType.overdue:
        return 3;
      case InvoiceNotificationType.dueToday:
        return 2;
      case InvoiceNotificationType.closing:
        return 1;
    }
  }
}
