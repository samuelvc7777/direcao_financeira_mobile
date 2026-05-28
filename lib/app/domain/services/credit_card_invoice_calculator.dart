class CreditCardInvoiceEntry {
  const CreditCardInvoiceEntry({
    required this.type,
    required this.amountCents,
    required this.transactionDate,
    this.installmentNumber,
    this.installmentCount,
  });

  final CreditCardInvoiceEntryType type;
  final int amountCents;
  final DateTime transactionDate;
  final int? installmentNumber;
  final int? installmentCount;

  int get displayedAmountCents {
    return CreditCardInvoiceCalculator.resolveEffectiveAmountCents(
      amountCents: amountCents,
      installmentNumber: installmentNumber,
      installmentCount: installmentCount,
    );
  }
}

enum CreditCardInvoiceEntryType {
  expense,
  income;
}

class CreditCardInvoiceSummary {
  const CreditCardInvoiceSummary({
    required this.openInvoiceCents,
    required this.closedInvoiceCents,
    required this.payableInvoiceCents,
    required this.outstandingBalanceCents,
    this.openInvoiceClosingDate,
    this.nextDueDate,
    this.isInvoiceDueToday = false,
    this.isInvoiceOverdue = false,
  });

  final int openInvoiceCents;
  final int closedInvoiceCents;
  final int payableInvoiceCents;
  final int outstandingBalanceCents;
  final DateTime? openInvoiceClosingDate;
  final DateTime? nextDueDate;
  final bool isInvoiceDueToday;
  final bool isInvoiceOverdue;
}

class CreditCardInvoiceReference {
  const CreditCardInvoiceReference({
    required this.referenceMonth,
    required this.referenceYear,
  });

  final int referenceMonth;
  final int referenceYear;
}

class CreditCardInvoiceDates {
  const CreditCardInvoiceDates({
    required this.closingDate,
    required this.dueDate,
  });

  final DateTime closingDate;
  final DateTime dueDate;
}

class CreditCardPersistedInvoice {
  const CreditCardPersistedInvoice({
    required this.totalCents,
    required this.paidCents,
    required this.closingDate,
    required this.dueDate,
  });

  final int totalCents;
  final int paidCents;
  final DateTime closingDate;
  final DateTime dueDate;
}

class CreditCardInvoiceCalculator {
  const CreditCardInvoiceCalculator();

  static int resolveEffectiveAmountCents({
    required int amountCents,
    int? installmentNumber,
    int? installmentCount,
  }) {
    final count = installmentCount;
    final number = installmentNumber;
    if (count != null && count > 1) {
      final base = amountCents ~/ count;
      final remainder = amountCents % count;
      if (number != null && number > 0 && number <= remainder) {
        return base + 1;
      }
      return base;
    }

    return amountCents;
  }

  CreditCardInvoiceSummary calculate({
    required Iterable<CreditCardInvoiceEntry> entries,
    required int closingDay,
    required int dueDay,
    required DateTime now,
  }) {
    final normalizedToday = DateTime(now.year, now.month, now.day);
    final invoicesByClosingDate = <String, _InvoiceBucket>{};
    var paymentPoolCents = 0;

    for (final entry in entries) {
      final displayedAmountCents = entry.displayedAmountCents;
      if (displayedAmountCents <= 0) {
        continue;
      }

      if (entry.type == CreditCardInvoiceEntryType.income) {
        paymentPoolCents += displayedAmountCents;
        continue;
      }

      final closingDate = _resolveClosingDate(
        purchaseDate: entry.transactionDate,
        closingDay: closingDay,
      );
      final invoiceKey = _dateKey(closingDate);
      final dueDate = buildInvoiceDates(
        referenceYear: closingDate.year,
        referenceMonth: closingDate.month,
        closingDay: closingDay,
        dueDay: dueDay,
      ).dueDate;
      final bucket = invoicesByClosingDate.putIfAbsent(
        invoiceKey,
        () => _InvoiceBucket(closingDate: closingDate, dueDate: dueDate),
      );
      bucket.totalCents += displayedAmountCents;
    }

    final invoices = invoicesByClosingDate.values.toList()
      ..sort((a, b) => a.closingDate.compareTo(b.closingDate));

    for (final invoice in invoices) {
      if (paymentPoolCents <= 0) {
        invoice.outstandingCents = invoice.totalCents;
        continue;
      }

      final paidCents = paymentPoolCents >= invoice.totalCents
          ? invoice.totalCents
          : paymentPoolCents;
      invoice.outstandingCents = invoice.totalCents - paidCents;
      paymentPoolCents -= paidCents;
    }

    final outstandingInvoices = invoices
        .where((invoice) => invoice.outstandingCents > 0)
        .toList();
    final openInvoice = outstandingInvoices.firstWhere(
      (invoice) => _isAfterDate(invoice.closingDate, normalizedToday),
      orElse: () => _EmptyInvoiceBucket(),
    );
    final closedInvoices = outstandingInvoices
        .where((invoice) => !_isAfterDate(invoice.closingDate, normalizedToday))
        .toList();
    final payableInvoices = closedInvoices
        .where((invoice) => !_isAfterDate(invoice.dueDate, normalizedToday))
        .toList();
    final nextDueDate = closedInvoices.isEmpty
        ? null
        : (closedInvoices..sort((a, b) => a.dueDate.compareTo(b.dueDate)))
              .first
              .dueDate;

    return CreditCardInvoiceSummary(
      openInvoiceCents: openInvoice.outstandingCents,
      closedInvoiceCents: closedInvoices.fold<int>(
        0,
        (sum, invoice) => sum + invoice.outstandingCents,
      ),
      payableInvoiceCents: payableInvoices.fold<int>(
        0,
        (sum, invoice) => sum + invoice.outstandingCents,
      ),
      outstandingBalanceCents: outstandingInvoices.fold<int>(
        0,
        (sum, invoice) => sum + invoice.outstandingCents,
      ),
      openInvoiceClosingDate: openInvoice is _EmptyInvoiceBucket
          ? null
          : openInvoice.closingDate,
      nextDueDate: nextDueDate,
      isInvoiceDueToday: payableInvoices.any(
        (invoice) => _isSameDate(invoice.dueDate, normalizedToday),
      ),
      isInvoiceOverdue: payableInvoices.any(
        (invoice) => _isBeforeDate(invoice.dueDate, normalizedToday),
      ),
    );
  }

  CreditCardInvoiceSummary summarizePersistedInvoices({
    required Iterable<CreditCardPersistedInvoice> invoices,
    required DateTime now,
  }) {
    final normalizedToday = DateTime(now.year, now.month, now.day);
    final buckets = invoices
        .map(
          (invoice) => _InvoiceBucket(
            closingDate: DateTime(
              invoice.closingDate.year,
              invoice.closingDate.month,
              invoice.closingDate.day,
            ),
            dueDate: DateTime(
              invoice.dueDate.year,
              invoice.dueDate.month,
              invoice.dueDate.day,
            ),
          )..outstandingCents = (invoice.totalCents - invoice.paidCents)
              .clamp(0, invoice.totalCents)
              .toInt(),
        )
        .where((invoice) => invoice.outstandingCents > 0)
        .toList()
      ..sort((a, b) => a.closingDate.compareTo(b.closingDate));

    final openInvoices = buckets
        .where((invoice) => _isAfterDate(invoice.closingDate, normalizedToday))
        .toList();
    final closedInvoices = buckets
        .where((invoice) => !_isAfterDate(invoice.closingDate, normalizedToday))
        .toList();
    final payableInvoices = closedInvoices
        .where((invoice) => !_isAfterDate(invoice.dueDate, normalizedToday))
        .toList();
    final nextDueDate = closedInvoices.isEmpty
        ? null
        : (closedInvoices..sort((a, b) => a.dueDate.compareTo(b.dueDate)))
              .first
              .dueDate;
    final openInvoiceClosingDate = openInvoices.isEmpty
        ? null
        : (openInvoices..sort((a, b) => a.closingDate.compareTo(b.closingDate)))
              .first
              .closingDate;

    return CreditCardInvoiceSummary(
      openInvoiceCents: openInvoices.fold<int>(
        0,
        (sum, invoice) => sum + invoice.outstandingCents,
      ),
      closedInvoiceCents: closedInvoices.fold<int>(
        0,
        (sum, invoice) => sum + invoice.outstandingCents,
      ),
      payableInvoiceCents: payableInvoices.fold<int>(
        0,
        (sum, invoice) => sum + invoice.outstandingCents,
      ),
      outstandingBalanceCents: buckets.fold<int>(
        0,
        (sum, invoice) => sum + invoice.outstandingCents,
      ),
      openInvoiceClosingDate: openInvoiceClosingDate,
      nextDueDate: nextDueDate,
      isInvoiceDueToday: payableInvoices.any(
        (invoice) => _isSameDate(invoice.dueDate, normalizedToday),
      ),
      isInvoiceOverdue: payableInvoices.any(
        (invoice) => _isBeforeDate(invoice.dueDate, normalizedToday),
      ),
    );
  }

  CreditCardInvoiceReference resolveInvoiceReference({
    required DateTime transactionDate,
    required int closingDay,
  }) {
    final closingDate = _resolveClosingDate(
      purchaseDate: transactionDate,
      closingDay: closingDay,
    );
    return CreditCardInvoiceReference(
      referenceMonth: closingDate.month,
      referenceYear: closingDate.year,
    );
  }

  CreditCardInvoiceDates buildInvoiceDates({
    required int referenceYear,
    required int referenceMonth,
    required int closingDay,
    required int dueDay,
  }) {
    final closingDate = _safeDate(referenceYear, referenceMonth, closingDay);
    final dueDate = _resolveDueDate(
      closingDate: closingDate,
      closingDay: closingDay,
      dueDay: dueDay,
    );
    return CreditCardInvoiceDates(
      closingDate: closingDate,
      dueDate: dueDate,
    );
  }

  DateTime _resolveClosingDate({
    required DateTime purchaseDate,
    required int closingDay,
  }) {
    final normalizedPurchaseDate = DateTime(
      purchaseDate.year,
      purchaseDate.month,
      purchaseDate.day,
    );
    final currentMonthClosingDate = _safeDate(
      normalizedPurchaseDate.year,
      normalizedPurchaseDate.month,
      closingDay,
    );

    if (!_isAfterDate(normalizedPurchaseDate, currentMonthClosingDate)) {
      return currentMonthClosingDate;
    }

    return _safeDate(
      normalizedPurchaseDate.year,
      normalizedPurchaseDate.month + 1,
      closingDay,
    );
  }

  DateTime _resolveDueDate({
    required DateTime closingDate,
    required int closingDay,
    required int dueDay,
  }) {
    if (dueDay > closingDay) {
      return _safeDate(closingDate.year, closingDate.month, dueDay);
    }

    return _safeDate(closingDate.year, closingDate.month + 1, dueDay);
  }

  DateTime _safeDate(int year, int month, int day) {
    final normalizedMonth = DateTime(year, month);
    final lastDayOfMonth = DateTime(
      normalizedMonth.year,
      normalizedMonth.month + 1,
      0,
    ).day;
    return DateTime(
      normalizedMonth.year,
      normalizedMonth.month,
      day.clamp(1, lastDayOfMonth),
    );
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  bool _isSameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  bool _isAfterDate(DateTime left, DateTime right) =>
      DateTime(left.year, left.month, left.day).isAfter(
        DateTime(right.year, right.month, right.day),
      );

  bool _isBeforeDate(DateTime left, DateTime right) =>
      DateTime(left.year, left.month, left.day).isBefore(
        DateTime(right.year, right.month, right.day),
      );
}

class _InvoiceBucket {
  _InvoiceBucket({
    required this.closingDate,
    required this.dueDate,
  });

  final DateTime closingDate;
  final DateTime dueDate;
  int totalCents = 0;
  int outstandingCents = 0;
}

class _EmptyInvoiceBucket extends _InvoiceBucket {
  _EmptyInvoiceBucket()
      : super(
          closingDate: DateTime(1970),
          dueDate: DateTime(1970),
        );
}
