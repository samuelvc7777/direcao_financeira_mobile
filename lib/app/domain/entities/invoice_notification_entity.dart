enum InvoiceNotificationType { closing, dueToday, overdue }

enum InvoiceNotificationDispatchStatus { scheduled, cancelled }

class InvoiceNotificationCandidate {
  const InvoiceNotificationCandidate({
    required this.cardId,
    required this.cardName,
    required this.type,
    required this.eventDate,
    required this.scheduledAt,
    required this.amountCents,
    required this.cycleKey,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int cardId;
  final String cardName;
  final InvoiceNotificationType type;
  final DateTime eventDate;
  final DateTime scheduledAt;
  final int amountCents;
  final String cycleKey;
  final String title;
  final String body;
  final String payload;

  String get dedupeKey =>
      '$cardId:${type.name}:$cycleKey:${_dateKey(eventDate)}';

  int get notificationId => dedupeKey.hashCode.abs() % 2147483647;
}

class InvoiceNotificationDispatchRecord {
  const InvoiceNotificationDispatchRecord({
    required this.dedupeKey,
    required this.notificationId,
    required this.cardId,
    required this.type,
    required this.eventDate,
    required this.scheduledAt,
    required this.status,
    required this.updatedAt,
  });

  final String dedupeKey;
  final int notificationId;
  final int cardId;
  final InvoiceNotificationType type;
  final DateTime eventDate;
  final DateTime scheduledAt;
  final InvoiceNotificationDispatchStatus status;
  final DateTime updatedAt;

  InvoiceNotificationDispatchRecord copyWith({
    InvoiceNotificationDispatchStatus? status,
    DateTime? updatedAt,
  }) {
    return InvoiceNotificationDispatchRecord(
      dedupeKey: dedupeKey,
      notificationId: notificationId,
      cardId: cardId,
      type: type,
      eventDate: eventDate,
      scheduledAt: scheduledAt,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

String invoiceNotificationDateKey(DateTime date) => _dateKey(date);

String _dateKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return normalized.toIso8601String().split('T').first;
}
