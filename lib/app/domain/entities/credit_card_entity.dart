class CreditCardEntity {
  final int id;
  final String name;
  final String brand;
  final String color;
  final int limitCents;
  final int availableLimitCents;
  final int closingDay;
  final int dueDay;
  final String lastFourDigits;
  final bool isActive;
  final int openInvoiceCents;
  final int closedInvoiceCents;
  final int payableInvoiceCents;
  final DateTime? openInvoiceClosingDate;
  final DateTime? nextDueDate;
  final bool isInvoiceDueToday;
  final bool isInvoiceOverdue;

  CreditCardEntity({
    required this.id,
    required this.name,
    required this.brand,
    required this.color,
    required this.limitCents,
    required this.availableLimitCents,
    required this.closingDay,
    required this.dueDay,
    required this.lastFourDigits,
    required this.isActive,
    this.openInvoiceCents = 0,
    this.closedInvoiceCents = 0,
    this.payableInvoiceCents = 0,
    this.openInvoiceClosingDate,
    this.nextDueDate,
    this.isInvoiceDueToday = false,
    this.isInvoiceOverdue = false,
  });

  double get limit => limitCents / 100.0;
  double get availableLimit => availableLimitCents / 100.0;
  double get usedLimit => (limitCents - availableLimitCents) / 100.0;
  double get openInvoice => openInvoiceCents / 100.0;
  double get closedInvoice => closedInvoiceCents / 100.0;
  double get payableInvoice => payableInvoiceCents / 100.0;
  bool get hasOpenInvoice => openInvoiceCents > 0;
  bool get hasClosedInvoice => closedInvoiceCents > 0;
  bool get canPayInvoice => payableInvoiceCents > 0;
  double get usedPercentage => limitCents > 0 ? (limitCents - availableLimitCents) / limitCents : 0.0;
}
