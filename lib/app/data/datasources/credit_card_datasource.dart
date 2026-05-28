import '../models/credit_card_model.dart';

abstract class ICreditCardDataSource {
  Future<List<CreditCardModel>> getCreditCards();
  Future<CreditCardModel> createCreditCard({
    required String name,
    required String brand,
    required String color,
    required int limitCents,
    required int closingDay,
    required int dueDay,
    required String lastFourDigits,
  });
  Future<CreditCardModel> updateCreditCard({
    required int id,
    required String name,
    required String brand,
    required String color,
    required int limitCents,
    required int closingDay,
    required int dueDay,
    required String lastFourDigits,
    bool? isActive,
  });
  Future<void> deactivateCreditCard(int id);
  Future<void> reactivateCreditCard(int id);
}
