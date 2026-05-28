import '../entities/resolved_google_api_key_entity.dart';
import '../repositories/i_google_api_config_repository.dart';

class ResolvedGoogleApiKeyService {
  ResolvedGoogleApiKeyService({
    required this.repository,
    required String fallbackGoogleMapsApiKey,
  }) : _fallbackGoogleMapsApiKey = fallbackGoogleMapsApiKey;

  final IGoogleApiConfigRepository repository;
  final String _fallbackGoogleMapsApiKey;
  ResolvedGoogleApiKeyEntity? _cached;

  String get currentValue =>
      _cached?.value ?? _normalize(_fallbackGoogleMapsApiKey);

  Future<ResolvedGoogleApiKeyEntity> resolve({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cached != null) {
      return _cached!;
    }

    final result = await repository.getConfig();
    final remoteValue = result.fold<String?>(
      (_) => null,
      (config) => config?.googleApiKey,
    );

    final remote = _normalize(remoteValue);
    if (remote.isNotEmpty) {
      return _cached = ResolvedGoogleApiKeyEntity(
        value: remote,
        source: ResolvedGoogleApiKeySource.remote,
      );
    }

    final fallback = _normalize(_fallbackGoogleMapsApiKey);
    return _cached = ResolvedGoogleApiKeyEntity(
      value: fallback,
      source: fallback.isEmpty
          ? ResolvedGoogleApiKeySource.empty
          : ResolvedGoogleApiKeySource.fallback,
    );
  }

  String _normalize(String? value) => value?.trim() ?? '';
}
