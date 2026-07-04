import '../../domain/entities/referral_entity.dart';

class ReferralSummaryModel extends ReferralSummaryEntity {
  const ReferralSummaryModel({
    required super.referralCode,
    required super.pendingCents,
    required super.approvedCents,
    required super.paidCents,
    required super.totalReferrals,
  });
}

class ReferralModel extends ReferralEntity {
  const ReferralModel({
    required super.id,
    required super.referredUserName,
    required super.referredUserEmail,
    required super.status,
    required super.rewardCents,
    super.createdAt,
    super.approvedAt,
    super.paidAt,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    final referredUser = json['referredUser'];
    final referredUserMap = referredUser is Map
        ? Map<String, dynamic>.from(referredUser)
        : const <String, dynamic>{};

    return ReferralModel(
      id: json['id'] as int,
      referredUserName: referredUserMap['name']?.toString() ?? 'Indicado',
      referredUserEmail: referredUserMap['email']?.toString() ?? '',
      status: json['status']?.toString() ?? 'registered',
      rewardCents: json['rewardCents'] as int? ?? 0,
      createdAt: _parseDate(json['createdAt']),
      approvedAt: _parseDate(json['approvedAt']),
      paidAt: _parseDate(json['paidAt']),
    );
  }
}

class PixWithdrawalModel extends PixWithdrawalEntity {
  const PixWithdrawalModel({
    required super.id,
    required super.amountCents,
    required super.status,
    required super.pixKey,
    required super.cpf,
    super.createdAt,
    super.updatedAt,
  });

  factory PixWithdrawalModel.fromJson(Map<String, dynamic> json) {
    return PixWithdrawalModel(
      id: json['id'] as int,
      amountCents: json['amountCents'] as int? ?? 0,
      status: json['status']?.toString() ?? 'requested',
      pixKey: json['pixKey']?.toString() ?? '',
      cpf: json['cpf']?.toString() ?? '',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null || value.toString().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}
