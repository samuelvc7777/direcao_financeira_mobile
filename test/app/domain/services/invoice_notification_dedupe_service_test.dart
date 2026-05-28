import 'package:direcao_financeira_mobile/app/domain/entities/invoice_notification_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/services/invoice_notification_dedupe_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InvoiceNotificationDedupeService service;

  setUp(() {
    service = InvoiceNotificationDedupeService();
  });

  test('remove candidato ja agendado no mesmo dia', () {
    final candidate = _candidate(InvoiceNotificationType.overdue);
    final pending = service.filterPending(
      candidates: [candidate],
      records: [_record(candidate)],
    );

    expect(pending, isEmpty);
  });

  test('prioriza vencimento quando fechamento e vencimento coincidem', () {
    final closing = _candidate(InvoiceNotificationType.closing);
    final due = _candidate(InvoiceNotificationType.dueToday);

    final pending = service.filterPending(
      candidates: [closing, due],
      records: const [],
    );

    expect(pending, hasLength(1));
    expect(pending.single.type, InvoiceNotificationType.dueToday);
  });
}

InvoiceNotificationCandidate _candidate(InvoiceNotificationType type) {
  return InvoiceNotificationCandidate(
    cardId: 1,
    cardName: 'Nubank',
    type: type,
    eventDate: DateTime(2026, 5, 26),
    scheduledAt: DateTime(2026, 5, 26, 10),
    amountCents: 10000,
    cycleKey: '2026-05-26',
    title: 'Titulo',
    body: 'Corpo',
    payload: 'invoice:${type.name}:card:1',
  );
}

InvoiceNotificationDispatchRecord _record(
  InvoiceNotificationCandidate candidate,
) {
  return InvoiceNotificationDispatchRecord(
    dedupeKey: candidate.dedupeKey,
    notificationId: candidate.notificationId,
    cardId: candidate.cardId,
    type: candidate.type,
    eventDate: candidate.eventDate,
    scheduledAt: candidate.scheduledAt,
    status: InvoiceNotificationDispatchStatus.scheduled,
    updatedAt: DateTime(2026, 5, 26, 9),
  );
}
