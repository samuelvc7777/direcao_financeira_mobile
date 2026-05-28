enum ResolvedGoogleApiKeySource { remote, fallback, empty }

class ResolvedGoogleApiKeyEntity {
  const ResolvedGoogleApiKeyEntity({required this.value, required this.source});

  final String value;
  final ResolvedGoogleApiKeySource source;

  bool get isAvailable => value.trim().isNotEmpty;
}
