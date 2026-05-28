import '../entities/subscription_entity.dart';

enum PremiumAccessBlockReason { noSubscription, expiredOrInactive }

class PremiumAccessDecision {
  const PremiumAccessDecision._({required this.isAllowed, this.reason});

  const PremiumAccessDecision.allowed() : this._(isAllowed: true);

  const PremiumAccessDecision.blocked(PremiumAccessBlockReason reason)
    : this._(isAllowed: false, reason: reason);

  final bool isAllowed;
  final PremiumAccessBlockReason? reason;
}

class PremiumAccessPolicy {
  const PremiumAccessPolicy();

  PremiumAccessDecision evaluate(SubscriptionEntity? subscription) {
    if (subscription == null) {
      return const PremiumAccessDecision.blocked(
        PremiumAccessBlockReason.noSubscription,
      );
    }

    if (subscription.grantsAccess) {
      return const PremiumAccessDecision.allowed();
    }

    return const PremiumAccessDecision.blocked(
      PremiumAccessBlockReason.expiredOrInactive,
    );
  }
}
