import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/credit_card_entity.dart';

abstract class ICreditCardRepository {
  Future<Either<Failure, List<CreditCardEntity>>> getCreditCards();
  Future<Either<Failure, CreditCardEntity>> createCreditCard({
    required String name,
    required String brand,
    required String color,
    required int limitCents,
    required int closingDay,
    required int dueDay,
    required String lastFourDigits,
  });
  Future<Either<Failure, CreditCardEntity>> updateCreditCard({
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
  Future<Either<Failure, void>> deactivateCreditCard(int id);
  Future<Either<Failure, void>> reactivateCreditCard(int id);
}
