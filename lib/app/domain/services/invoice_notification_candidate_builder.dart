import '../entities/credit_card_entity.dart';
import '../entities/invoice_notification_entity.dart';
import 'invoice_notification_text_formatter.dart';

class InvoiceNotificationCandidateBuilder {
  InvoiceNotificationCandidateBuilder({
    InvoiceNotificationTextFormatter? formatter,
  }) : _formatter = formatter ?? InvoiceNotificationTextFormatter();

  final InvoiceNotificationTextFormatter _formatter;

  List<InvoiceNotificationCandidate> buildCandidates({
    required Iterable<CreditCardEntity> cards,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final candidates = <InvoiceNotificationCandidate>[];

    for (final card in cards) {
      if (!card.isActive) {
        continue;
      }

      final closingDate =
          _normalizeDate(card.openInvoiceClosingDate) ??
          _dateForConfiguredDay(today, card.closingDay);
      if (_isSameDay(closingDate, today)) {
        candidates.add(
          _candidate(
            card: card,
            type: InvoiceNotificationType.closing,
            eventDate: today,
            amountCents: card.openInvoiceCents,
            cycleKey: invoiceNotificationDateKey(closingDate),
            now: now,
          ),
        );
      }

      final dueDate =
          _normalizeDate(card.nextDueDate) ??
          _dateForConfiguredDay(today, card.dueDay);
      if (card.payableInvoiceCents > 0 && _isSameDay(dueDate, today)) {
        candidates.add(
          _candidate(
            card: card,
            type: InvoiceNotificationType.dueToday,
            eventDate: today,
            amountCents: card.payableInvoiceCents,
            cycleKey: invoiceNotificationDateKey(dueDate),
            now: now,
          ),
        );
      }

      if (card.payableInvoiceCents > 0 && _isOverdue(card, dueDate, today)) {
        candidates.add(
          _candidate(
            card: card,
            type: InvoiceNotificationType.overdue,
            eventDate: today,
            amountCents: card.payableInvoiceCents,
            cycleKey: invoiceNotificationDateKey(dueDate),
            now: now,
          ),
        );
      }
    }

    return candidates;
  }

  InvoiceNotificationCandidate _candidate({
    required CreditCardEntity card,
    required InvoiceNotificationType type,
    required DateTime eventDate,
    required int amountCents,
    required String cycleKey,
    required DateTime now,
  }) {
    final draft = InvoiceNotificationCandidateDraft(
      cardName: card.name,
      type: type,
      amountCents: amountCents,
    );
    final scheduledAt = _nextScheduleAt(eventDate, now);

    return InvoiceNotificationCandidate(
      cardId: card.id,
      cardName: card.name,
      type: type,
      eventDate: eventDate,
      scheduledAt: scheduledAt,
      amountCents: amountCents,
      cycleKey: cycleKey,
      title: _formatter.titleFor(draft),
      body: _formatter.bodyFor(draft),
      payload: 'invoice:${type.name}:card:${card.id}',
    );
  }

  DateTime _nextScheduleAt(DateTime eventDate, DateTime now) {
    final todayAtTen = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      10,
    );
    if (todayAtTen.isAfter(now)) {
      return todayAtTen;
    }
    return now.add(const Duration(minutes: 1));
  }

  bool _isOverdue(CreditCardEntity card, DateTime dueDate, DateTime today) {
    return card.isInvoiceOverdue || dueDate.isBefore(today);
  }

  DateTime _dateForConfiguredDay(DateTime baseDate, int configuredDay) {
    final lastDay = DateTime(baseDate.year, baseDate.month + 1, 0).day;
    final safeDay = configuredDay.clamp(1, lastDay);
    return DateTime(baseDate.year, baseDate.month, safeDay);
  }

  DateTime? _normalizeDate(DateTime? date) {
    if (date == null) {
      return null;
    }
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
