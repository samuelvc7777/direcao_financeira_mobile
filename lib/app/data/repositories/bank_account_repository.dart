import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../core/errors/failures.dart';
import '../../core/network/api_error_mapper.dart';
import '../../core/network/api_request_logger.dart';
import '../../domain/entities/bank_account_entity.dart';
import '../../domain/repositories/i_bank_account_repository.dart';
import '../datasources/bank_account_datasource.dart';

class BankAccountRepository implements IBankAccountRepository {
  static const _legacyWalletName = 'Dinheiro';
  static const _legacyWalletBankName = 'Dinheiro';
  static const _legacyWalletColor = '#06B6D4';

  BankAccountRepository({
    required this.dataSource,
    required this.apiErrorMapper,
    required this.apiRequestLogger,
  });

  final IBankAccountDataSource dataSource;
  final ApiErrorMapper apiErrorMapper;
  final ApiRequestLogger apiRequestLogger;
  Future<void>? _walletMigrationFuture;

  @override
  Future<Either<Failure, List<BankAccountEntity>>> getBankAccounts() async {
    try {
      final accounts = await dataSource.getBankAccounts();
      final migratedAccounts = await _ensureLegacyWalletAccount(accounts);
      return Right(migratedAccounts);
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'BankAccountRepository.getBankAccounts',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao carregar contas bancarias.',
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'BankAccountRepository.getBankAccounts',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao carregar contas bancarias.',
        ),
      );
    }
  }

  Future<List<BankAccountEntity>> _ensureLegacyWalletAccount(
    List<BankAccountEntity> accounts,
  ) async {
    final hasWallet = accounts.any(
      (account) => account.accountType == AccountType.wallet,
    );
    final hasActiveWallet = accounts.any(
      (account) =>
          account.accountType == AccountType.wallet && account.isActive,
    );
    if (hasWallet && hasActiveWallet) {
      return accounts;
    }

    if (_walletMigrationFuture != null) {
      await _walletMigrationFuture;
      return dataSource.getBankAccounts();
    }

    _walletMigrationFuture = _runLegacyWalletMigration(accounts);
    try {
      await _walletMigrationFuture;
    } finally {
      _walletMigrationFuture = null;
    }

    return dataSource.getBankAccounts();
  }

  Future<void> _runLegacyWalletMigration(
    List<BankAccountEntity> accounts,
  ) async {
    final wallet = accounts
        .where((account) => account.accountType == AccountType.wallet)
        .toList();
    if (wallet.isNotEmpty) {
      if (wallet.any((account) => account.isActive)) {
        return;
      }

      await reactivateBankAccount(wallet.first.id);
      return;
    }

    await createBankAccount(
      name: _legacyWalletName,
      bankName: _legacyWalletBankName,
      color: _legacyWalletColor,
      accountType: AccountType.wallet,
      initialBalanceCents: 0,
    );
  }

  @override
  Future<Either<Failure, BankAccountEntity>> createBankAccount({
    required String name,
    required String bankName,
    required String color,
    required AccountType accountType,
    required int initialBalanceCents,
  }) async {
    try {
      return Right(
        await dataSource.createBankAccount(
          name: name,
          bankName: bankName,
          color: color,
          accountType: accountType,
          initialBalanceCents: initialBalanceCents,
        ),
      );
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'BankAccountRepository.createBankAccount',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao criar conta bancaria.',
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'BankAccountRepository.createBankAccount',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao criar conta bancaria.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, BankAccountEntity>> updateBankAccount({
    required int id,
    required String name,
    required String bankName,
    required String color,
    required AccountType accountType,
    required int initialBalanceCents,
    bool? isActive,
  }) async {
    try {
      return Right(
        await dataSource.updateBankAccount(
          id: id,
          name: name,
          bankName: bankName,
          color: color,
          accountType: accountType,
          initialBalanceCents: initialBalanceCents,
          isActive: isActive,
        ),
      );
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'BankAccountRepository.updateBankAccount',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao atualizar conta bancaria.',
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'BankAccountRepository.updateBankAccount',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao atualizar conta bancaria.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deactivateBankAccount(int id) async {
    try {
      await dataSource.deactivateBankAccount(id);
      return const Right(null);
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'BankAccountRepository.deactivateBankAccount',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao desativar conta bancaria.',
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'BankAccountRepository.deactivateBankAccount',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao desativar conta bancaria.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> reactivateBankAccount(int id) async {
    try {
      await dataSource.reactivateBankAccount(id);
      return const Right(null);
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'BankAccountRepository.reactivateBankAccount',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao reativar conta bancaria.',
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'BankAccountRepository.reactivateBankAccount',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao reativar conta bancaria.',
        ),
      );
    }
  }
}
