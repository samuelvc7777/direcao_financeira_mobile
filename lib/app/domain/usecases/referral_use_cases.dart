import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/referral_entity.dart';
import '../entities/referral_settings_entity.dart';
import '../repositories/i_referral_repository.dart';
import '../repositories/i_referral_settings_repository.dart';

const referralMinimumWithdrawalCents = 2500;

class GetReferralSummaryUseCase {
  const GetReferralSummaryUseCase(this.repository);

  final IReferralRepository repository;

  Future<Either<Failure, ReferralSummaryEntity>> call() {
    return repository.getSummary();
  }
}

class GetReferralsUseCase {
  const GetReferralsUseCase(this.repository);

  final IReferralRepository repository;

  Future<Either<Failure, List<ReferralEntity>>> call() {
    return repository.getReferrals();
  }
}

class GetPixWithdrawalsUseCase {
  const GetPixWithdrawalsUseCase(this.repository);

  final IReferralRepository repository;

  Future<Either<Failure, List<PixWithdrawalEntity>>> call() {
    return repository.getWithdrawals();
  }
}

class RequestPixWithdrawalUseCase {
  const RequestPixWithdrawalUseCase(this.repository, {this.settingsRepository});

  final IReferralRepository repository;
  final IReferralSettingsRepository? settingsRepository;

  Future<Either<Failure, PixWithdrawalEntity>> call({
    required int amountCents,
    required String cpf,
    required String pixKey,
  }) async {
    final normalizedCpf = cpf.replaceAll(RegExp(r'\D'), '');
    final normalizedPixKey = pixKey.trim();

    if (amountCents <= 0) {
      return Left(ValidationFailure('Informe um valor valido para saque.'));
    }

    final settings = await _loadSettings();
    if (!settings.enabled) {
      return Left(ValidationFailure('O programa de indicacoes esta inativo.'));
    }

    if (amountCents < settings.minimumWithdrawalCents) {
      return Left(
        ValidationFailure(
          'O saque minimo e de ${_formatMoney(settings.minimumWithdrawalCents)}.',
        ),
      );
    }

    if (normalizedCpf.length != 11) {
      return Left(ValidationFailure('Informe um CPF valido.'));
    }

    if (normalizedPixKey.length < 3) {
      return Left(ValidationFailure('Informe uma chave Pix valida.'));
    }

    return repository.requestPixWithdrawal(
      amountCents: amountCents,
      cpf: normalizedCpf,
      pixKey: normalizedPixKey,
    );
  }

  Future<ReferralSettingsEntity> _loadSettings() async {
    final repository = settingsRepository;
    if (repository == null) {
      return const ReferralSettingsEntity();
    }

    final result = await repository.getSettings();
    return result.getOrElse(() => const ReferralSettingsEntity());
  }

  String _formatMoney(int cents) {
    final reais = cents ~/ 100;
    final centavos = (cents % 100).toString().padLeft(2, '0');
    return 'R\$ $reais,$centavos';
  }
}
