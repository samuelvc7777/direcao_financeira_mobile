enum BackendProviderKind {
  nest('nest'),
  supabase('supabase');

  const BackendProviderKind(this.value);

  final String value;

  static BackendProviderKind fromValue(String? value) {
    for (final provider in BackendProviderKind.values) {
      if (provider.value == value?.trim().toLowerCase()) {
        return provider;
      }
    }

    return BackendProviderKind.nest;
  }
}

const _defaultHelpVideoCatalogJson = '''
[
  {
    "id": "video-teste-ajuda",
    "title": "Video de teste",
    "description": "Video temporario para validar o player interno da tela de ajuda.",
    "youtubeVideoId": "HxgGW_ECu0w",
    "category": "Teste",
    "durationLabel": "Teste",
    "isFeatured": true,
    "sortOrder": 0
  }
]
''';

class AppEnvironment {
  const AppEnvironment({
    required this.backendProvider,
    required this.apiBaseUrl,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.enableRealtime,
    this.googleMapsApiKey = '',
    this.helpVideoCatalogJson = '',
    this.helpWhatsappPhone = '',
    this.helpWhatsappUrl = '',
    this.helpWhatsappInitialMessage = '',
  });

  final BackendProviderKind backendProvider;
  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool enableRealtime;
  final String googleMapsApiKey;
  final String helpVideoCatalogJson;
  final String helpWhatsappPhone;
  final String helpWhatsappUrl;
  final String helpWhatsappInitialMessage;

  factory AppEnvironment.fromDartDefines() {
    return AppEnvironment(
      backendProvider: BackendProviderKind.fromValue(
        const String.fromEnvironment(
          'BACKEND_PROVIDER',
          defaultValue: 'supabase',
        ),
      ),
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://barbie-inseverable-audrianna.ngrok-free.dev',
      ),
      supabaseUrl: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://canucibuhdqdctxaanjh.supabase.co',
      ),
      supabaseAnonKey: const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhbnVjaWJ1aGRxZGN0eGFhbmpoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxODMzMTYsImV4cCI6MjA4OTc1OTMxNn0.UCANhliXHklhNQvhBBywBUGr3PpxKKT9BaNtkG7bD6E',
      ),
      enableRealtime:
          const String.fromEnvironment(
            'ENABLE_REALTIME',
            defaultValue: 'true',
          ) ==
          'true',
      // Fallback local usado quando a configuracao remota Company.googleApiKey nao estiver disponivel.
      googleMapsApiKey: const String.fromEnvironment(
        'GOOGLE_MAPS_API_KEY',
        defaultValue: 'AIzaSyAB51isR9aIJCirO0YowxRujWA9S2VKokk',
      ),
      helpVideoCatalogJson: const String.fromEnvironment(
        'HELP_VIDEO_CATALOG_JSON',
        defaultValue: _defaultHelpVideoCatalogJson,
      ),
      helpWhatsappPhone: const String.fromEnvironment(
        'HELP_WHATSAPP_PHONE',
        defaultValue: '',
      ),
      helpWhatsappUrl: const String.fromEnvironment(
        'HELP_WHATSAPP_URL',
        defaultValue: '',
      ),
      helpWhatsappInitialMessage: const String.fromEnvironment(
        'HELP_WHATSAPP_INITIAL_MESSAGE',
        defaultValue: 'Ola, preciso de ajuda com o Direcao Financeira.',
      ),
    );
  }
}
