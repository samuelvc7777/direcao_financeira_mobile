import '../models/referral_model.dart';

abstract class IReferralRemoteDataSource {
  Future<ReferralSummaryModel> getSummary();
  Future<List<ReferralModel>> getReferrals();
  Future<List<PixWithdrawalModel>> getWithdrawals();
  Future<PixWithdrawalModel> requestPixWithdrawal({
    required int amountCents,
    required String cpf,
    required String pixKey,
  });
}
