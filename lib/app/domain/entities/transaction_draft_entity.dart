import 'transaction_entity.dart';

class TransactionDraftEntity {
  final TransactionType type;
  final AssetType assetType;
  final int amountCents;
  final int categoryId;
  final String description;
  final DateTime transactionDate;
  final int? bankAccountId;
  final int? creditCardId;
  final int? installmentCount;
  final int? recurrenceCount;

  const TransactionDraftEntity({
    required this.type,
    required this.assetType,
    required this.amountCents,
    required this.categoryId,
    required this.description,
    required this.transactionDate,
    this.bankAccountId,
    this.creditCardId,
    this.installmentCount,
    this.recurrenceCount,
  });
}
