import '../../domain/entities/bank_account_entity.dart';
import '../models/bank_account_model.dart';

abstract class IBankAccountDataSource {
  Future<List<BankAccountModel>> getBankAccounts();
  Future<BankAccountModel> createBankAccount({
    required String name,
    required String bankName,
    required String color,
    required AccountType accountType,
    required int initialBalanceCents,
  });
  Future<BankAccountModel> updateBankAccount({
    required int id,
    required String name,
    required String bankName,
    required String color,
    required AccountType accountType,
    required int initialBalanceCents,
    bool? isActive,
  });
  Future<void> deactivateBankAccount(int id);
  Future<void> reactivateBankAccount(int id);
}
