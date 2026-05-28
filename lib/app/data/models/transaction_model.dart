import '../../domain/entities/transaction_entity.dart';
import '../mappers/transaction_codecs.dart';

class TransactionModel extends TransactionEntity {
  TransactionModel({
    required super.id,
    required super.type,
    required super.status,
    required super.assetType,
    required super.amountCents,
    required super.categoryId,
    required super.description,
    required super.transactionDate,
    super.bankAccountId,
    super.creditCardId,
    super.invoiceId,
    super.installmentGroupId,
    super.installmentNumber,
    super.installmentCount,
    super.recurrenceGroupId,
    super.recurrenceNumber,
    super.recurrenceCount,
    super.categoryName,
    super.categoryColor,
    super.categoryIcon,
    super.assetName,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final bankAccount = json['bankAccount'];
    final creditCard = json['creditCard'];
    final categoryJson = category is Map
        ? Map<String, dynamic>.from(category)
        : null;
    final bankAccountJson = bankAccount is Map
        ? Map<String, dynamic>.from(bankAccount)
        : null;
    final creditCardJson = creditCard is Map
        ? Map<String, dynamic>.from(creditCard)
        : null;

    return TransactionModel(
      id: json['id'] as int,
      type: TransactionTypeCodec.decode(json['type'] as String),
      status: TransactionStatusCodec.decode(json['status'] as String),
      assetType: AssetTypeCodec.decode(json['assetType'] as String),
      amountCents: json['amountCents'] as int,
      categoryId: json['categoryId'] as int,
      description: json['description'] as String,
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      bankAccountId: json['bankAccountId'] as int?,
      creditCardId: json['creditCardId'] as int?,
      invoiceId: json['invoiceId'] as int?,
      installmentGroupId: json['installmentGroupId'] as String?,
      installmentNumber: json['installmentNumber'] as int?,
      installmentCount: json['installmentCount'] as int?,
      recurrenceGroupId: json['recurrenceGroupId'] as String?,
      recurrenceNumber: json['recurrenceNumber'] as int?,
      recurrenceCount: json['recurrenceCount'] as int?,
      categoryName: categoryJson?['name'] as String?,
      categoryColor: categoryJson?['color'] as String?,
      categoryIcon: categoryJson?['icon'] as String?,
      assetName:
          (bankAccountJson?['name'] ?? creditCardJson?['name']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': TransactionTypeCodec.encode(type),
      'status': TransactionStatusCodec.encode(status),
      'assetType': AssetTypeCodec.encode(assetType),
      'amountCents': amountCents,
      'categoryId': categoryId,
      'description': description,
      'transactionDate': transactionDate.toIso8601String(),
      if (bankAccountId != null) 'bankAccountId': bankAccountId,
      if (creditCardId != null) 'creditCardId': creditCardId,
      if (invoiceId != null) 'invoiceId': invoiceId,
      if (installmentGroupId != null) 'installmentGroupId': installmentGroupId,
      if (installmentNumber != null) 'installmentNumber': installmentNumber,
      if (installmentCount != null) 'installmentCount': installmentCount,
      if (recurrenceGroupId != null) 'recurrenceGroupId': recurrenceGroupId,
      if (recurrenceNumber != null) 'recurrenceNumber': recurrenceNumber,
      if (recurrenceCount != null) 'recurrenceCount': recurrenceCount,
    };
  }
}
