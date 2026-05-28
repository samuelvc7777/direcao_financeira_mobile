import 'package:direcao_financeira_mobile/app/domain/services/credit_card_invoice_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreditCardInvoiceCalculator', () {
    const calculator = CreditCardInvoiceCalculator();

    test('usa o valor parcelado correto para limitar e fatura aberta', () {
      final summary = calculator.calculate(
        entries: [
          CreditCardInvoiceEntry(
            type: CreditCardInvoiceEntryType.expense,
            amountCents: 30000,
            transactionDate: DateTime(2026, 3, 5),
            installmentNumber: 1,
            installmentCount: 3,
          ),
          CreditCardInvoiceEntry(
            type: CreditCardInvoiceEntryType.expense,
            amountCents: 30000,
            transactionDate: DateTime(2026, 4, 5),
            installmentNumber: 2,
            installmentCount: 3,
          ),
          CreditCardInvoiceEntry(
            type: CreditCardInvoiceEntryType.expense,
            amountCents: 30000,
            transactionDate: DateTime(2026, 5, 5),
            installmentNumber: 3,
            installmentCount: 3,
          ),
        ],
        closingDay: 10,
        dueDay: 20,
        now: DateTime(2026, 3, 8),
      );

      expect(summary.openInvoiceCents, 10000);
      expect(summary.closedInvoiceCents, 0);
      expect(summary.outstandingBalanceCents, 30000);
    });

    test('move fatura fechada para pagavel no dia do vencimento', () {
      final summary = calculator.calculate(
        entries: [
          CreditCardInvoiceEntry(
            type: CreditCardInvoiceEntryType.expense,
            amountCents: 120000,
            transactionDate: DateTime(2026, 3, 1),
          ),
        ],
        closingDay: 10,
        dueDay: 20,
        now: DateTime(2026, 3, 20),
      );

      expect(summary.closedInvoiceCents, 120000);
      expect(summary.payableInvoiceCents, 120000);
      expect(summary.isInvoiceDueToday, isTrue);
      expect(summary.isInvoiceOverdue, isFalse);
    });

    test('abate pagamentos nas faturas mais antigas antes de liberar limite', () {
      final summary = calculator.calculate(
        entries: [
          CreditCardInvoiceEntry(
            type: CreditCardInvoiceEntryType.expense,
            amountCents: 50000,
            transactionDate: DateTime(2026, 2, 2),
          ),
          CreditCardInvoiceEntry(
            type: CreditCardInvoiceEntryType.expense,
            amountCents: 80000,
            transactionDate: DateTime(2026, 3, 2),
          ),
          CreditCardInvoiceEntry(
            type: CreditCardInvoiceEntryType.income,
            amountCents: 30000,
            transactionDate: DateTime(2026, 3, 15),
          ),
        ],
        closingDay: 10,
        dueDay: 20,
        now: DateTime(2026, 3, 25),
      );

      expect(summary.closedInvoiceCents, 100000);
      expect(summary.payableInvoiceCents, 100000);
      expect(summary.outstandingBalanceCents, 100000);
      expect(summary.isInvoiceOverdue, isTrue);
    });

    test('resume faturas persistidas sem recalcular pelo fechamento atual', () {
      final summary = calculator.summarizePersistedInvoices(
        invoices: [
          CreditCardPersistedInvoice(
            totalCents: 45000,
            paidCents: 0,
            closingDate: DateTime(2026, 3, 14),
            dueDate: DateTime(2026, 3, 19),
          ),
          CreditCardPersistedInvoice(
            totalCents: 12000,
            paidCents: 0,
            closingDate: DateTime(2026, 4, 14),
            dueDate: DateTime(2026, 4, 19),
          ),
        ],
        now: DateTime(2026, 3, 25),
      );

      expect(summary.closedInvoiceCents, 45000);
      expect(summary.openInvoiceCents, 12000);
      expect(summary.payableInvoiceCents, 45000);
      expect(summary.isInvoiceOverdue, isTrue);
    });

    test('resolve referencia e datas da fatura com fechamento e vencimento', () {
      final reference = calculator.resolveInvoiceReference(
        transactionDate: DateTime(2026, 3, 15),
        closingDay: 14,
      );
      final dates = calculator.buildInvoiceDates(
        referenceYear: reference.referenceYear,
        referenceMonth: reference.referenceMonth,
        closingDay: 14,
        dueDay: 19,
      );

      expect(reference.referenceMonth, 4);
      expect(reference.referenceYear, 2026);
      expect(dates.closingDate, DateTime(2026, 4, 14));
      expect(dates.dueDate, DateTime(2026, 4, 19));
    });
  });
}
