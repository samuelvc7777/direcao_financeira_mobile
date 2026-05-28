class StoreProductEntity {
  final String productId;
  final String title;
  final String description;
  final String priceLabel;
  final String? recurringPriceLabel;
  final double rawPrice;
  final String currencyCode;
  final int? trialDays;
  final String? trialLabel;
  final String? offerToken;
  final String? basePlanId;
  final String? offerId;

  const StoreProductEntity({
    required this.productId,
    required this.title,
    required this.description,
    required this.priceLabel,
    this.recurringPriceLabel,
    required this.rawPrice,
    required this.currencyCode,
    this.trialDays,
    this.trialLabel,
    this.offerToken,
    this.basePlanId,
    this.offerId,
  });

  bool get hasFreeTrial => trialDays != null && trialDays! > 0;
}
