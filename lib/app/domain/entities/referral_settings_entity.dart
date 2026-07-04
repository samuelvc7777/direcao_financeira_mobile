class ReferralSettingsEntity {
  const ReferralSettingsEntity({
    this.enabled = true,
    this.showEntryPoint = true,
    this.showRegisterInput = true,
    this.rewardCents = 500,
    this.minimumWithdrawalCents = 2500,
    this.requiresPaidSubscription = true,
    this.updatedAt,
  });

  final bool enabled;
  final bool showEntryPoint;
  final bool showRegisterInput;
  final int rewardCents;
  final int minimumWithdrawalCents;
  final bool requiresPaidSubscription;
  final DateTime? updatedAt;

  bool get canShowEntryPoint => enabled && showEntryPoint;
  bool get canShowRegisterInput => enabled && showRegisterInput;
}
