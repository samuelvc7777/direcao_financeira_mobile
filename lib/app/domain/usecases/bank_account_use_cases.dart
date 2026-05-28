import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/bank_account_entity.dart';
import '../repositories/i_bank_account_repository.dart';

class LoadBankAccountsUseCase {
  LoadBankAccountsUseCase(this._repository);

  final IBankAccountRepository _repository;

  Future<Either<Failure, List<BankAccountEntity>>> call() {
    return _repository.getBankAccounts();
  }
}

class CreateBankAccountUseCase {
  CreateBankAccountUseCase(this._repository);

  final IBankAccountRepository _repository;

  Future<Either<Failure, BankAccountEntity>> call({
    required String name,
    required String bankName,
    required String color,
    required AccountType accountType,
    required int initialBalanceCents,
  }) {
    return _repository.createBankAccount(
      name: name,
      bankName: bankName,
      color: color,
      accountType: accountType,
      initialBalanceCents: initialBalanceCents,
    );
  }
}

class UpdateBankAccountUseCase {
  UpdateBankAccountUseCase(this._repository);

  final IBankAccountRepository _repository;

  Future<Either<Failure, BankAccountEntity>> call({
    required int id,
    required String name,
    required String bankName,
    required String color,
    required AccountType accountType,
    required int initialBalanceCents,
    bool? isActive,
  }) {
    return _repository.updateBankAccount(
      id: id,
      name: name,
      bankName: bankName,
      color: color,
      accountType: accountType,
      initialBalanceCents: initialBalanceCents,
      isActive: isActive,
    );
  }
}

class DeactivateBankAccountUseCase {
  DeactivateBankAccountUseCase(this._repository);

  final IBankAccountRepository _repository;

  Future<Either<Failure, void>> call(int id) {
    return _repository.deactivateBankAccount(id);
  }
}

class ReactivateBankAccountUseCase {
  ReactivateBankAccountUseCase(this._repository);

  final IBankAccountRepository _repository;

  Future<Either<Failure, void>> call(int id) {
    return _repository.reactivateBankAccount(id);
  }
}
