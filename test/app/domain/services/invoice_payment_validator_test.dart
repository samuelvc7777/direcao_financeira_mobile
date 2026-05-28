import 'package:direcao_financeira_mobile/app/domain/services/invoice_payment_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InvoicePaymentValidator', () {
    const validator = InvoicePaymentValidator();

    test('resolve pagamento total com o saldo em aberto', () {
      final result = validator.validate(
        const InvoicePaymentChoice(
          bankAccountId: 1,
          creditCardId: 2,
          mode: InvoicePaymentMode.total,
          payableInvoiceCents: 120000,
        ),
      );

      expect(result.isValid, isTrue);
      expect(result.resolvedAmountCents, 120000);
    });

    test('aceita pagamento parcial maior que zero e menor que a fatura', () {
      final result = validator.validate(
        const InvoicePaymentChoice(
          bankAccountId: 1,
          creditCardId: 2,
          mode: InvoicePaymentMode.partial,
          amountCents: 45000,
          payableInvoiceCents: 120000,
        ),
      );

      expect(result.isValid, isTrue);
      expect(result.resolvedAmountCents, 45000);
    });

    test('rejeita pagamento parcial vazio, zero ou negativo', () {
      for (final amountCents in <int?>[null, 0, -1]) {
        final result = validator.validate(
          InvoicePaymentChoice(
            bankAccountId: 1,
            creditCardId: 2,
            mode: InvoicePaymentMode.partial,
            amountCents: amountCents,
            payableInvoiceCents: 120000,
          ),
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, 'Informe um valor parcial maior que zero.');
      }
    });

    test('rejeita pagamento parcial igual ou maior que a fatura', () {
      for (final amountCents in <int>[120000, 130000]) {
        final result = validator.validate(
          InvoicePaymentChoice(
            bankAccountId: 1,
            creditCardId: 2,
            mode: InvoicePaymentMode.partial,
            amountCents: amountCents,
            payableInvoiceCents: 120000,
          ),
        );

        expect(result.isValid, isFalse);
        expect(
          result.errorMessage,
          'O pagamento parcial deve ser menor que o saldo em aberto.',
        );
      }
    });
  });
}
