import 'package:direcao_financeira_mobile/app/domain/entities/bank_account_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/credit_card_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/services/invoice_payment_validator.dart';
import 'package:direcao_financeira_mobile/app/presentation/modules/home/widgets/invoice_payment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe escolha de conta e modo de pagamento', (tester) async {
    InvoicePaymentFormResult? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InvoicePaymentSheet(
            card: _card(),
            accounts: [_account()],
            onSubmit: (result) async {
              submitted = result;
              return null;
            },
          ),
        ),
      ),
    );

    expect(find.text('Escolha a conta'), findsOneWidget);
    expect(find.text('Tipo de pagamento'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Parcial'), findsOneWidget);

    await tester.tap(find.byKey(const Key('invoice-account-10')));
    await tester.tap(find.byKey(const Key('invoice-payment-confirm-button')));
    await tester.pumpAndSettle();

    expect(submitted?.bankAccount.id, 10);
    expect(submitted?.mode, InvoicePaymentMode.total);
    expect(submitted?.amountCents, isNull);
  });

  testWidgets('mostra campo de valor apenas no pagamento parcial', (
    tester,
  ) async {
    InvoicePaymentFormResult? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InvoicePaymentSheet(
            card: _card(),
            accounts: [_account()],
            onSubmit: (result) async {
              submitted = result;
              return null;
            },
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('invoice-partial-amount-field')), findsNothing);

    await tester.tap(find.byKey(const Key('invoice-account-10')));
    await tester.tap(find.byKey(const Key('invoice-partial-mode-option')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('invoice-partial-amount-field')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('invoice-partial-amount-field')),
      'R\$ 450,00',
    );
    await tester.ensureVisible(
      find.byKey(const Key('invoice-payment-confirm-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('invoice-payment-confirm-button')));
    await tester.pumpAndSettle();

    expect(submitted?.mode, InvoicePaymentMode.partial);
    expect(submitted?.amountCents, 45000);
  });

  testWidgets('mantem o sheet aberto quando o controller retorna erro', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InvoicePaymentSheet(
            card: _card(),
            accounts: [_account()],
            onSubmit: (_) async => 'Valor invalido.',
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('invoice-account-10')));
    await tester.tap(find.byKey(const Key('invoice-payment-confirm-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('invoice-payment-error')), findsOneWidget);
    expect(find.text('Valor invalido.'), findsOneWidget);
  });
}

BankAccountEntity _account() {
  return BankAccountEntity(
    id: 10,
    name: 'Conta Principal',
    bankName: 'Nubank',
    color: '#123456',
    accountType: AccountType.checking,
    initialBalanceCents: 200000,
    currentBalanceCents: 200000,
    isActive: true,
  );
}

CreditCardEntity _card() {
  return CreditCardEntity(
    id: 20,
    name: 'Visa',
    brand: 'visa',
    color: '#654321',
    limitCents: 500000,
    availableLimitCents: 300000,
    closingDay: 10,
    dueDay: 20,
    lastFourDigits: '1234',
    isActive: true,
    closedInvoiceCents: 120000,
    payableInvoiceCents: 120000,
  );
}
