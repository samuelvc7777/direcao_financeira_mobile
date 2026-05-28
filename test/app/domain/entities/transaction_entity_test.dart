import 'package:direcao_financeira_mobile/app/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TransactionEntity distribui o valor entre as parcelas', () {
    final first = TransactionEntity(
      id: 1,
      type: TransactionType.expense,
      status: TransactionStatus.cleared,
      assetType: AssetType.creditCard,
      amountCents: 25450,
      categoryId: 7,
      description: 'Compra parcelada',
      transactionDate: DateTime(2026, 3, 12),
      creditCardId: 1,
      installmentGroupId: 'grp-1',
      installmentNumber: 1,
      installmentCount: 12,
    );
    final eleventh = TransactionEntity(
      id: 2,
      type: TransactionType.expense,
      status: TransactionStatus.cleared,
      assetType: AssetType.creditCard,
      amountCents: 25450,
      categoryId: 7,
      description: 'Compra parcelada',
      transactionDate: DateTime(2026, 3, 12),
      creditCardId: 1,
      installmentGroupId: 'grp-1',
      installmentNumber: 11,
      installmentCount: 12,
    );

    expect(first.displayedAmountCents, 2121);
    expect(eleventh.displayedAmountCents, 2120);
    expect(first.displayedAmount, 21.21);
    expect(eleventh.displayedAmount, 21.20);
  });

  test('TransactionEntity expõe serie recorrente corretamente', () {
    final recurring = TransactionEntity(
      id: 3,
      type: TransactionType.expense,
      status: TransactionStatus.pending,
      assetType: AssetType.bankAccount,
      amountCents: 12990,
      categoryId: 7,
      description: 'Assinatura mensal',
      transactionDate: DateTime(2026, 5, 12),
      bankAccountId: 1,
      recurrenceGroupId: 'rec-1',
      recurrenceNumber: 2,
      recurrenceCount: 6,
    );

    expect(recurring.hasRecurrenceSeries, isTrue);
    expect(recurring.hasAnySeries, isTrue);
    expect(recurring.seriesNumber, 2);
    expect(recurring.seriesCount, 6);
  });
}
