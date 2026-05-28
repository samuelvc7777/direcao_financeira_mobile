import '../../domain/entities/invoice_notification_entity.dart';

class InvoiceNotificationDispatchModel
    extends InvoiceNotificationDispatchRecord {
  const InvoiceNotificationDispatchModel({
    required super.dedupeKey,
    required super.notificationId,
    required super.cardId,
    required super.type,
    required super.eventDate,
    required super.scheduledAt,
    required super.status,
    required super.updatedAt,
  });

  factory InvoiceNotificationDispatchModel.fromEntity(
    InvoiceNotificationDispatchRecord record,
  ) {
    return InvoiceNotificationDispatchModel(
      dedupeKey: record.dedupeKey,
      notificationId: record.notificationId,
      cardId: record.cardId,
      type: record.type,
      eventDate: record.eventDate,
      scheduledAt: record.scheduledAt,
      status: record.status,
      updatedAt: record.updatedAt,
    );
  }

  factory InvoiceNotificationDispatchModel.fromJson(Map<String, dynamic> json) {
    return InvoiceNotificationDispatchModel(
      dedupeKey: json['dedupeKey'] as String,
      notificationId: json['notificationId'] as int,
      cardId: json['cardId'] as int,
      type: InvoiceNotificationType.values.byName(json['type'] as String),
      eventDate: DateTime.parse(json['eventDate'] as String),
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      status: InvoiceNotificationDispatchStatus.values.byName(
        json['status'] as String,
      ),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dedupeKey': dedupeKey,
      'notificationId': notificationId,
      'cardId': cardId,
      'type': type.name,
      'eventDate': eventDate.toIso8601String(),
      'scheduledAt': scheduledAt.toIso8601String(),
      'status': status.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
