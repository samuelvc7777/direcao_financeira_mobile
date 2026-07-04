import 'package:direcao_financeira_mobile/app/data/datasources/referral_settings_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('le configuracoes de indicacao da linha Company', () async {
    final dataSource = SupabaseReferralSettingsDataSource(
      companySettingsLoader: () async => {
        'referralSettings': {
          'enabled': false,
          'showEntryPoint': false,
          'showRegisterInput': false,
          'rewardCents': 700,
          'minimumWithdrawalCents': 5000,
          'requiresPaidSubscription': true,
        },
        'updatedAt': '2026-06-29T10:00:00.000Z',
      },
    );

    final settings = await dataSource.getSettings();

    expect(settings.enabled, isFalse);
    expect(settings.canShowEntryPoint, isFalse);
    expect(settings.canShowRegisterInput, isFalse);
    expect(settings.rewardCents, 700);
    expect(settings.minimumWithdrawalCents, 5000);
    expect(settings.requiresPaidSubscription, isTrue);
    expect(settings.updatedAt, DateTime.parse('2026-06-29T10:00:00.000Z'));
  });

  test('usa defaults seguros quando Company nao retorna linha', () async {
    final dataSource = SupabaseReferralSettingsDataSource(
      companySettingsLoader: () async => null,
    );

    final settings = await dataSource.getSettings();

    expect(settings.enabled, isTrue);
    expect(settings.canShowEntryPoint, isTrue);
    expect(settings.canShowRegisterInput, isTrue);
    expect(settings.rewardCents, 500);
    expect(settings.minimumWithdrawalCents, 2500);
  });
}
