class ReferralSummaryEntity {
  const ReferralSummaryEntity({
    required this.referralCode,
    required this.pendingCents,
    required this.approvedCents,
    required this.paidCents,
    required this.totalReferrals,
  });

  final String referralCode;
  final int pendingCents;
  final int approvedCents;
  final int paidCents;
  final int totalReferrals;
}

class ReferralEntity {
  const ReferralEntity({
    required this.id,
    required this.referredUserName,
    required this.referredUserEmail,
    required this.status,
    required this.rewardCents,
    this.createdAt,
    this.approvedAt,
    this.paidAt,
  });

  final int id;
  final String referredUserName;
  final String referredUserEmail;
  final String status;
  final int rewardCents;
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final DateTime? paidAt;
}

class PixWithdrawalEntity {
  const PixWithdrawalEntity({
    required this.id,
    required this.amountCents,
    required this.status,
    required this.pixKey,
    required this.cpf,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int amountCents;
  final String status;
  final String pixKey;
  final String cpf;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
