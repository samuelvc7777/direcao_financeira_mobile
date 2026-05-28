import 'package:direcao_financeira_mobile/app/data/mappers/bank_account_codec.dart';
import 'package:direcao_financeira_mobile/app/data/mappers/category_type_codec.dart';
import 'package:direcao_financeira_mobile/app/data/mappers/transaction_codecs.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/bank_account_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/category_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TransactionTypeCodec codifica e decodifica tipos de transacao', () {
    expect(TransactionTypeCodec.encode(TransactionType.income), 'INCOME');
    expect(TransactionTypeCodec.encode(TransactionType.expense), 'EXPENSE');
    expect(TransactionTypeCodec.decode('income'), TransactionType.income);
    expect(TransactionTypeCodec.decode('EXPENSE'), TransactionType.expense);
  });

  test(
    'AssetTypeCodec e TransactionStatusCodec preservam o dialeto do provider',
    () {
      expect(AssetTypeCodec.encode(AssetType.bankAccount), 'BANK_ACCOUNT');
      expect(AssetTypeCodec.encode(AssetType.creditCard), 'CREDIT_CARD');
      expect(AssetTypeCodec.decode('BANK_ACCOUNT'), AssetType.bankAccount);
      expect(AssetTypeCodec.decode('credit_card'), AssetType.creditCard);
      expect(
        TransactionStatusCodec.encode(TransactionStatus.pending),
        'PENDING',
      );
      expect(
        TransactionStatusCodec.decode('CLEARED'),
        TransactionStatus.cleared,
      );
      expect(
        TransactionStatusCodec.decode('qualquer-coisa'),
        TransactionStatus.pending,
      );
    },
  );

  test('AccountTypeCodec centraliza o mapeamento de contas bancarias', () {
    expect(AccountTypeCodec.encode(AccountType.checking), 'CHECKING');
    expect(AccountTypeCodec.encode(AccountType.savings), 'SAVINGS');
    expect(AccountTypeCodec.encode(AccountType.wallet), 'WALLET');
    expect(AccountTypeCodec.encode(AccountType.investment), 'WALLET');
    expect(AccountTypeCodec.decode('CHECKING'), AccountType.checking);
    expect(AccountTypeCodec.decode('SAVINGS'), AccountType.savings);
    expect(AccountTypeCodec.decode('WALLET'), AccountType.wallet);
  });

  test(
    'CategoryTypeCodec falha para tipo invalido e evita vazar valor estranho ao dominio',
    () {
      expect(CategoryTypeCodec.encode(CategoryType.income), 'INCOME');
      expect(CategoryTypeCodec.encode(CategoryType.expense), 'EXPENSE');
      expect(CategoryTypeCodec.decode('income'), CategoryType.income);
      expect(CategoryTypeCodec.decode('EXPENSE'), CategoryType.expense);
      expect(() => CategoryTypeCodec.decode('bonus'), throwsArgumentError);
    },
  );
}
