import '../../domain/entities/credit_card_entity.dart';

class CreditCardModel extends CreditCardEntity {
  CreditCardModel({
    required super.id,
    required super.name,
    required super.brand,
    required super.color,
    required super.limitCents,
    required super.availableLimitCents,
    required super.closingDay,
    required super.dueDay,
    required super.lastFourDigits,
    required super.isActive,
    super.openInvoiceCents,
    super.closedInvoiceCents,
    super.payableInvoiceCents,
    super.openInvoiceClosingDate,
    super.nextDueDate,
    super.isInvoiceDueToday,
    super.isInvoiceOverdue,
  });

  factory CreditCardModel.fromJson(Map<String, dynamic> json) {
    final limitCents = _intFromJson(json['limitCents']);

    return CreditCardModel(
      id: _intFromJson(json['id']),
      name: _stringFromJson(json['name'], fallback: 'Cartao'),
      brand: _stringFromJson(json['brand'], fallback: 'Cartao'),
      color: (json['color'] as String?) ?? '#8B5CF6',
      limitCents: limitCents,
      availableLimitCents: _intFromJson(
        json['availableLimitCents'],
        fallback: limitCents,
      ),
      closingDay: _intFromJson(json['closingDay'], fallback: 1),
      dueDay: _intFromJson(json['dueDay'], fallback: 1),
      lastFourDigits: _stringFromJson(json['lastFourDigits'], fallback: '0000'),
      isActive: json['isActive'] as bool? ?? true,
      openInvoiceCents: _intFromJson(json['openInvoiceCents']),
      closedInvoiceCents: _intFromJson(json['closedInvoiceCents']),
      payableInvoiceCents: _intFromJson(json['payableInvoiceCents']),
      openInvoiceClosingDate: json['openInvoiceClosingDate'] == null
          ? null
          : DateTime.tryParse(json['openInvoiceClosingDate'].toString()),
      nextDueDate: json['nextDueDate'] == null
          ? null
          : DateTime.tryParse(json['nextDueDate'].toString()),
      isInvoiceDueToday: json['isInvoiceDueToday'] as bool? ?? false,
      isInvoiceOverdue: json['isInvoiceOverdue'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'color': color,
      'limitCents': limitCents,
      'availableLimitCents': availableLimitCents,
      'closingDay': closingDay,
      'dueDay': dueDay,
      'lastFourDigits': lastFourDigits,
      'isActive': isActive,
      'openInvoiceCents': openInvoiceCents,
      'closedInvoiceCents': closedInvoiceCents,
      'payableInvoiceCents': payableInvoiceCents,
      'openInvoiceClosingDate': openInvoiceClosingDate?.toIso8601String(),
      'nextDueDate': nextDueDate?.toIso8601String(),
      'isInvoiceDueToday': isInvoiceDueToday,
      'isInvoiceOverdue': isInvoiceOverdue,
    };
  }

  static int _intFromJson(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static String _stringFromJson(Object? value, {required String fallback}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }
}
