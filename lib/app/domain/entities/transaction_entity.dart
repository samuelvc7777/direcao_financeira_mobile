enum TransactionType {
  income,
  expense;

  String get label {
    switch (this) {
      case TransactionType.income:
        return 'Receita';
      case TransactionType.expense:
        return 'Despesa';
    }
  }
}

enum AssetType {
  bankAccount,
  creditCard;

  String get label {
    switch (this) {
      case AssetType.bankAccount:
        return 'Conta Bancaria';
      case AssetType.creditCard:
        return 'Cartao de Credito';
    }
  }
}

enum TransactionMutationScope {
  current,
  all;
}

enum TransactionStatus {
  cleared,
  pending;
}

const String kInternalInvoicePaymentDescriptionPrefix =
    '[sistema] pagamento_fatura:';

class TransactionEntity {
  final int id;
  final TransactionType type;
  final TransactionStatus status;
  final AssetType assetType;
  final int amountCents;
  final int categoryId;
  final String description;
  final DateTime transactionDate;
  final int? bankAccountId;
  final int? creditCardId;
  final int? invoiceId;
  final String? installmentGroupId;
  final int? installmentNumber;
  final int? installmentCount;
  final String? recurrenceGroupId;
  final int? recurrenceNumber;
  final int? recurrenceCount;

  // Campos extras que podem vir populados do backend (joins)
  final String? categoryName;
  final String? categoryColor;
  final String? categoryIcon;
  final String? assetName;

  TransactionEntity({
    required this.id,
    required this.type,
    required this.status,
    required this.assetType,
    required this.amountCents,
    required this.categoryId,
    required this.description,
    required this.transactionDate,
    this.bankAccountId,
    this.creditCardId,
    this.invoiceId,
    this.installmentGroupId,
    this.installmentNumber,
    this.installmentCount,
    this.recurrenceGroupId,
    this.recurrenceNumber,
    this.recurrenceCount,
    this.categoryName,
    this.categoryColor,
    this.categoryIcon,
    this.assetName,
  });

  double get amount => amountCents / 100.0;

  bool get hasInstallmentSeries =>
      installmentGroupId != null &&
      installmentNumber != null &&
      installmentCount != null;

  bool get hasRecurrenceSeries =>
      recurrenceGroupId != null &&
      recurrenceNumber != null &&
      recurrenceCount != null;

  bool get hasAnySeries => hasInstallmentSeries || hasRecurrenceSeries;

  int? get seriesNumber => installmentNumber ?? recurrenceNumber;

  int? get seriesCount => installmentCount ?? recurrenceCount;

  bool get isInternalInvoicePayment =>
      description.startsWith(kInternalInvoicePaymentDescriptionPrefix);

  int get displayedAmountCents {
    final count = installmentCount;
    final number = installmentNumber;
    if (count != null && count > 1) {
      final base = amountCents ~/ count;
      final remainder = amountCents % count;
      if (number != null && number > 0 && number <= remainder) {
        return base + 1;
      }
      return base;
    }

    return amountCents;
  }

  double get displayedAmount => displayedAmountCents / 100.0;
}
