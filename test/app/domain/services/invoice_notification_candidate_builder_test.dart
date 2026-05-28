import 'package:direcao_financeira_mobile/app/domain/entities/credit_card_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/invoice_notification_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/services/invoice_notification_candidate_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InvoiceNotificationCandidateBuilder builder;

  setUp(() {
    builder = InvoiceNotificationCandidateBuilder();
  });

  test('gera aviso diario para fatura vencida com valor pendente', () {
    final candidates = builder.buildCandidates(
      now: DateTime(2026, 5, 26, 9, 30),
      cards: [
        _card(
          closingDay: 20,
          payableInvoiceCents: 12345,
          nextDueDate: DateTime(2026, 5, 25),
          isInvoiceOverdue: true,
        ),
      ],
    );

    expect(candidates, hasLength(1));
    expect(candidates.single.type, InvoiceNotificationType.overdue);
    expect(candidates.single.scheduledAt, DateTime(2026, 5, 26, 10));
  });

  test('nao gera atraso quando a fatura foi paga', () {
    final candidates = builder.buildCandidates(
      now: DateTime(2026, 5, 26, 9, 30),
      cards: [
        _card(
          closingDay: 20,
          payableInvoiceCents: 0,
          nextDueDate: DateTime(2026, 5, 25),
          isInvoiceOverdue: true,
        ),
      ],
    );

    expect(candidates, isEmpty);
  });

  test('gera fechamento no dia cadastrado e ignora cartao inativo', () {
    final candidates = builder.buildCandidates(
      now: DateTime(2026, 5, 26, 8),
      cards: [
        _card(openInvoiceClosingDate: DateTime(2026, 5, 26)),
        _card(
          id: 2,
          isActive: false,
          openInvoiceClosingDate: DateTime(2026, 5, 26),
        ),
      ],
    );

    expect(candidates, hasLength(1));
    expect(candidates.single.type, InvoiceNotificationType.closing);
  });

  test('normaliza fechamento para ultimo dia valido do mes', () {
    final candidates = builder.buildCandidates(
      now: DateTime(2026, 2, 28, 8),
      cards: [_card(closingDay: 31, openInvoiceClosingDate: null)],
    );

    expect(candidates.single.type, InvoiceNotificationType.closing);
  });

  test('gera vencimento no dia com valor pendente', () {
    final candidates = builder.buildCandidates(
      now: DateTime(2026, 5, 26, 8),
      cards: [
        _card(
          payableInvoiceCents: 8500,
          nextDueDate: DateTime(2026, 5, 26),
          isInvoiceDueToday: true,
        ),
      ],
    );

    expect(
      candidates.any((item) => item.type == InvoiceNotificationType.dueToday),
      isTrue,
    );
  });
}

CreditCardEntity _card({
  int id = 1,
  bool isActive = true,
  int closingDay = 26,
  int dueDay = 26,
  int openInvoiceCents = 10000,
  int payableInvoiceCents = 0,
  DateTime? openInvoiceClosingDate,
  DateTime? nextDueDate,
  bool isInvoiceDueToday = false,
  bool isInvoiceOverdue = false,
}) {
  return CreditCardEntity(
    id: id,
    name: 'Nubank',
    brand: 'Visa',
    lastFourDigits: '1234',
    color: '#8B5CF6',
    limitCents: 100000,
    availableLimitCents: 90000,
    closingDay: closingDay,
    dueDay: dueDay,
    isActive: isActive,
    openInvoiceCents: openInvoiceCents,
    payableInvoiceCents: payableInvoiceCents,
    openInvoiceClosingDate: openInvoiceClosingDate,
    nextDueDate: nextDueDate,
    isInvoiceDueToday: isInvoiceDueToday,
    isInvoiceOverdue: isInvoiceOverdue,
  );
}
