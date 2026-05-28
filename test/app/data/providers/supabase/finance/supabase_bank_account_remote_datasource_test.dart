import 'package:direcao_financeira_mobile/app/data/providers/supabase/finance/supabase_bank_account_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isClearedBankAccountTransaction aceita apenas transacao liquidada', () {
    expect(
      isClearedBankAccountTransaction({
        'bankAccountId': 1,
        'type': 'INCOME',
        'status': 'CLEARED',
        'amountCents': 1000,
      }),
      isTrue,
    );
    expect(
      isClearedBankAccountTransaction({
        'bankAccountId': 1,
        'type': 'INCOME',
        'status': 'PENDING',
        'amountCents': 1000,
      }),
      isFalse,
    );
    expect(
      isClearedBankAccountTransaction({
        'bankAccountId': 1,
        'type': 'INCOME',
        'amountCents': 1000,
      }),
      isFalse,
    );
  });
}
