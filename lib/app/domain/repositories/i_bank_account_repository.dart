import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/bank_account_entity.dart';

abstract class IBankAccountRepository {
  Future<Either<Failure, List<BankAccountEntity>>> getBankAccounts();
  Future<Either<Failure, BankAccountEntity>> createBankAccount({
    required String name,
    required String bankName,
    required String color,
    required AccountType accountType,
    required int initialBalanceCents,
  });
  Future<Either<Failure, BankAccountEntity>> updateBankAccount({
    required int id,
    required String name,
    required String bankName,
    required String color,
    required AccountType accountType,
    required int initialBalanceCents,
    bool? isActive,
  });
  Future<Either<Failure, void>> deactivateBankAccount(int id);
  Future<Either<Failure, void>> reactivateBankAccount(int id);
}
