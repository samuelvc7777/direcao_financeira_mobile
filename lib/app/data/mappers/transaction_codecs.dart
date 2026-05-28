import '../../domain/entities/transaction_entity.dart';

class TransactionTypeCodec {
  const TransactionTypeCodec._();

  static String encode(TransactionType value) => value.name.toUpperCase();

  static TransactionType decode(String value) {
    return TransactionType.values.firstWhere(
      (type) => type.name.toUpperCase() == value.toUpperCase(),
      orElse: () => TransactionType.expense,
    );
  }
}

class AssetTypeCodec {
  const AssetTypeCodec._();

  static String encode(AssetType value) {
    switch (value) {
      case AssetType.bankAccount:
        return 'BANK_ACCOUNT';
      case AssetType.creditCard:
        return 'CREDIT_CARD';
    }
  }

  static AssetType decode(String value) {
    if (value.toUpperCase() == 'BANK_ACCOUNT') {
      return AssetType.bankAccount;
    }

    if (value.toUpperCase() == 'CREDIT_CARD') {
      return AssetType.creditCard;
    }

    return AssetType.bankAccount;
  }
}

class TransactionMutationScopeCodec {
  const TransactionMutationScopeCodec._();

  static String encode(TransactionMutationScope value) => value.name.toUpperCase();
}

class TransactionStatusCodec {
  const TransactionStatusCodec._();

  static String encode(TransactionStatus value) => value.name.toUpperCase();

  static TransactionStatus decode(String value) {
    if (value.toUpperCase() == 'CLEARED') {
      return TransactionStatus.cleared;
    }

    return TransactionStatus.pending;
  }
}
