const String playStoreMonthlySubscriptionProductId = 'premium_monthly';
const String playStoreAnnualSubscriptionProductId = 'anual';

const Set<String> supportedAndroidSubscriptionProductIds = {
  playStoreMonthlySubscriptionProductId,
  playStoreAnnualSubscriptionProductId,
};

bool isSupportedAndroidSubscriptionCode(String code) {
  return supportedAndroidSubscriptionProductIds.contains(code.trim());
}
