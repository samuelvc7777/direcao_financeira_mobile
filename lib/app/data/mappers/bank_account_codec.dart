import '../../domain/entities/bank_account_entity.dart';

class AccountTypeCodec {
  const AccountTypeCodec._();

  static String encode(AccountType value) {
    switch (value) {
      case AccountType.checking:
        return 'CHECKING';
      case AccountType.savings:
        return 'SAVINGS';
      case AccountType.wallet:
      case AccountType.investment:
      case AccountType.other:
        return 'WALLET';
    }
  }

  static AccountType decode(String value) {
    return AccountType.values.firstWhere(
      (type) => type.name.toUpperCase() == value.toUpperCase(),
      orElse: () => AccountType.wallet,
    );
  }
}
