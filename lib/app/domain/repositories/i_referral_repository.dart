import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/referral_entity.dart';

abstract class IReferralRepository {
  Future<Either<Failure, ReferralSummaryEntity>> getSummary();
  Future<Either<Failure, List<ReferralEntity>>> getReferrals();
  Future<Either<Failure, List<PixWithdrawalEntity>>> getWithdrawals();
  Future<Either<Failure, PixWithdrawalEntity>> requestPixWithdrawal({
    required int amountCents,
    required String cpf,
    required String pixKey,
  });
}
