import 'package:direcao_financeira_mobile/app/data/datasources/google_api_config_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('le googleApiKey e updatedAt da linha Company', () async {
    final dataSource = SupabaseGoogleApiConfigDataSource(
      companySettingsLoader: () async => {
        'googleApiKey': 'google-key',
        'updatedAt': '2026-05-27T10:00:00.000Z',
      },
    );

    final config = await dataSource.getConfig();

    expect(config?.googleApiKey, 'google-key');
    expect(config?.updatedAt, DateTime.parse('2026-05-27T10:00:00.000Z'));
  });

  test('retorna null quando Company nao retorna linha', () async {
    final dataSource = SupabaseGoogleApiConfigDataSource(
      companySettingsLoader: () async => null,
    );

    final config = await dataSource.getConfig();

    expect(config, isNull);
  });

  test('retorna null quando loader falha', () async {
    final dataSource = SupabaseGoogleApiConfigDataSource(
      companySettingsLoader: () async => throw Exception('falha remota'),
    );

    final config = await dataSource.getConfig();

    expect(config, isNull);
  });
}
