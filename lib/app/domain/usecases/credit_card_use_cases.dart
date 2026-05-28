import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/credit_card_entity.dart';
import '../repositories/i_credit_card_repository.dart';

class LoadCreditCardsUseCase {
  LoadCreditCardsUseCase(this._repository);

  final ICreditCardRepository _repository;

  Future<Either<Failure, List<CreditCardEntity>>> call() {
    return _repository.getCreditCards();
  }
}

class CreateCreditCardUseCase {
  CreateCreditCardUseCase(this._repository);

  final ICreditCardRepository _repository;

  Future<Either<Failure, CreditCardEntity>> call({
    required String name,
    required String brand,
    required String color,
    required int limitCents,
    required int closingDay,
    required int dueDay,
    required String lastFourDigits,
  }) {
    return _repository.createCreditCard(
      name: name,
      brand: brand,
      color: color,
      limitCents: limitCents,
      closingDay: closingDay,
      dueDay: dueDay,
      lastFourDigits: lastFourDigits,
    );
  }
}

class UpdateCreditCardUseCase {
  UpdateCreditCardUseCase(this._repository);

  final ICreditCardRepository _repository;

  Future<Either<Failure, CreditCardEntity>> call({
    required int id,
    required String name,
    required String brand,
    required String color,
    required int limitCents,
    required int closingDay,
    required int dueDay,
    required String lastFourDigits,
    bool? isActive,
  }) {
    return _repository.updateCreditCard(
      id: id,
      name: name,
      brand: brand,
      color: color,
      limitCents: limitCents,
      closingDay: closingDay,
      dueDay: dueDay,
      lastFourDigits: lastFourDigits,
      isActive: isActive,
    );
  }
}

class DeactivateCreditCardUseCase {
  DeactivateCreditCardUseCase(this._repository);

  final ICreditCardRepository _repository;

  Future<Either<Failure, void>> call(int id) {
    return _repository.deactivateCreditCard(id);
  }
}

class ReactivateCreditCardUseCase {
  ReactivateCreditCardUseCase(this._repository);

  final ICreditCardRepository _repository;

  Future<Either<Failure, void>> call(int id) {
    return _repository.reactivateCreditCard(id);
  }
}
