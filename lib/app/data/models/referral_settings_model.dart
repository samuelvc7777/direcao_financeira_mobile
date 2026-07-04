import '../../domain/entities/referral_settings_entity.dart';

class ReferralSettingsModel extends ReferralSettingsEntity {
  const ReferralSettingsModel({
    super.enabled,
    super.showEntryPoint,
    super.showRegisterInput,
    super.rewardCents,
    super.minimumWithdrawalCents,
    super.requiresPaidSubscription,
    super.updatedAt,
  });

  factory ReferralSettingsModel.fromCompanyRow(Map<String, dynamic>? row) {
    if (row == null) {
      return const ReferralSettingsModel();
    }

    final rawSettings = row['referralSettings'];
    final settings = rawSettings is Map
        ? Map<String, dynamic>.from(rawSettings)
        : const <String, dynamic>{};

    return ReferralSettingsModel(
      enabled: _bool(settings['enabled'], fallback: true),
      showEntryPoint: _bool(settings['showEntryPoint'], fallback: true),
      showRegisterInput: _bool(settings['showRegisterInput'], fallback: true),
      rewardCents: _positiveInt(settings['rewardCents'], fallback: 500),
      minimumWithdrawalCents: _positiveInt(
        settings['minimumWithdrawalCents'],
        fallback: 2500,
      ),
      requiresPaidSubscription: _bool(
        settings['requiresPaidSubscription'],
        fallback: true,
      ),
      updatedAt: DateTime.tryParse(row['updatedAt']?.toString() ?? ''),
    );
  }

  static bool _bool(Object? value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
    return fallback;
  }

  static int _positiveInt(Object? value, {required int fallback}) {
    if (value is int && value > 0) return value;
    if (value is num && value > 0) return value.round();
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed != null && parsed > 0 ? parsed : fallback;
  }
}
