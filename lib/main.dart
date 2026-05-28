import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/core/bindings/app_binding.dart';
import 'app/core/config/app_environment.dart';
import 'app/core/location/location_tracking_service.dart';
import 'app/core/notifications/notification_permission_service.dart';
import 'app/core/theme/app_scroll_behavior.dart';
import 'app/core/theme/app_theme.dart';
import 'app/data/local/get_storage_session_store.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await initializeDateFormatting('pt_BR', null);

  GoogleFonts.config.allowRuntimeFetching = false;

  final environment = AppEnvironment.fromDartDefines();
  if (environment.backendProvider == BackendProviderKind.supabase) {
    if (environment.supabaseUrl.trim().isEmpty ||
        environment.supabaseAnonKey.trim().isEmpty) {
      throw StateError(
        'SUPABASE_URL e SUPABASE_ANON_KEY precisam estar configurados quando BACKEND_PROVIDER=supabase.',
      );
    }

    final uri = Uri.tryParse(environment.supabaseUrl);
    debugPrint(
      '[main] Supabase configurado -> host=${uri?.host ?? 'invalido'} backendProvider=${environment.backendProvider.name}',
    );

    await Supabase.initialize(
      url: environment.supabaseUrl,
      anonKey: environment.supabaseAnonKey,
    );
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event != AuthChangeEvent.passwordRecovery) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.currentRoute != AppRoutes.resetPassword) {
          Get.offAllNamed(AppRoutes.resetPassword);
        }
      });
    });
  }

  final storage = GetStorage();
  final sessionStore = GetStorageSessionStore(storage: storage);
  final token = sessionStore.getToken();
  final hasAuthenticatedSession =
      environment.backendProvider == BackendProviderKind.supabase
      ? Supabase.instance.client.auth.currentSession != null
      : token != null && token.isNotEmpty;
  final initialRoute = hasAuthenticatedSession
      ? AppRoutes.initial
      : AppRoutes.login;

  await initializeLocationTrackingService(storage);
  const notificationPermissionService = NotificationPermissionService();
  await notificationPermissionService
      .requestAndroidNotificationPermissionIfNeeded();

  final isDarkMode = storage.read<bool>('isDarkMode');
  final themeMode = isDarkMode == null
      ? ThemeMode.system
      : (isDarkMode ? ThemeMode.dark : ThemeMode.light);

  runApp(
    MyApp(
      initialRoute: initialRoute,
      themeMode: themeMode,
      environment: environment,
      storage: storage,
    ),
  );
}

class MyApp extends StatelessWidget {
  static const Locale _defaultLocale = Locale('pt', 'BR');

  const MyApp({
    super.key,
    required this.initialRoute,
    required this.themeMode,
    required this.environment,
    required this.storage,
  });

  final String initialRoute;
  final ThemeMode themeMode;
  final AppEnvironment environment;
  final GetStorage storage;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      title: 'Dire\u00e7\u00e3o Financeira',
      locale: _defaultLocale,
      fallbackLocale: _defaultLocale,
      supportedLocales: const [_defaultLocale],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      initialBinding: AppBinding(environment: environment, storage: storage),
      initialRoute: initialRoute,
      getPages: AppPages.pages,
    );
  }
}
