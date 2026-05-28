import 'package:dartz/dartz.dart';
import 'package:direcao_financeira_mobile/app/core/errors/failures.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/google_api_config_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/resolved_google_api_key_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_google_api_config_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/services/resolved_google_api_key_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGoogleApiConfigRepository implements IGoogleApiConfigRepository {
  _FakeGoogleApiConfigRepository(this.result);

  final Either<Failure, GoogleApiConfigEntity?> result;

  @override
  Future<Either<Failure, GoogleApiConfigEntity?>> getConfig() async => result;
}

void main() {
  test('usa valor remoto valido antes do fallback local', () async {
    final service = ResolvedGoogleApiKeyService(
      repository: _FakeGoogleApiConfigRepository(
        const Right(GoogleApiConfigEntity(googleApiKey: ' remote-key ')),
      ),
      fallbackGoogleMapsApiKey: 'fallback-key',
    );

    final resolved = await service.resolve(forceRefresh: true);

    expect(resolved.value, 'remote-key');
    expect(resolved.source, ResolvedGoogleApiKeySource.remote);
  });

  test('usa fallback quando remoto e nulo vazio ou espacos', () async {
    for (final remote in <String?>[null, '', '   ']) {
      final service = ResolvedGoogleApiKeyService(
        repository: _FakeGoogleApiConfigRepository(
          Right(GoogleApiConfigEntity(googleApiKey: remote)),
        ),
        fallbackGoogleMapsApiKey: ' fallback-key ',
      );

      final resolved = await service.resolve(forceRefresh: true);

      expect(resolved.value, 'fallback-key');
      expect(resolved.source, ResolvedGoogleApiKeySource.fallback);
    }
  });

  test('usa fallback quando repository retorna falha', () async {
    final service = ResolvedGoogleApiKeyService(
      repository: _FakeGoogleApiConfigRepository(
        Left(ServerFailure('erro remoto')),
      ),
      fallbackGoogleMapsApiKey: 'fallback-key',
    );

    final resolved = await service.resolve(forceRefresh: true);

    expect(resolved.value, 'fallback-key');
    expect(resolved.source, ResolvedGoogleApiKeySource.fallback);
  });
}
