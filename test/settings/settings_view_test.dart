import 'package:direcao_financeira_mobile/app/core/app_bubble/app_bubble_service.dart';
import 'package:dartz/dartz.dart';
import 'package:direcao_financeira_mobile/app/core/errors/failures.dart';
import 'package:direcao_financeira_mobile/app/core/preferences/app_preferences.dart';
import 'package:direcao_financeira_mobile/app/core/theme/app_theme.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/user_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_auth_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/auth_session_use_cases.dart';
import 'package:direcao_financeira_mobile/app/presentation/modules/settings/settings_controller.dart';
import 'package:direcao_financeira_mobile/app/presentation/modules/settings/settings_view.dart';
import 'package:direcao_financeira_mobile/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeAuthRepository implements IAuthRepository {
  bool logoutCalled = false;
  UserEntity? storedUser;
  String? updatedProfilePhotoBase64;

  @override
  Either<Failure, UserEntity?> getStoredUser() => Right(storedUser);

  @override
  Future<Either<Failure, String?>> getToken() async => const Right(null);

  @override
  Future<Either<Failure, UserEntity>> login(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> logout() async {
    logoutCalled = true;
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserEntity>> register(
    String name,
    String email,
    String password,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> updatePassword(String password) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfilePhotoBase64(
    String? profilePhotoBase64,
  ) {
    updatedProfilePhotoBase64 = profilePhotoBase64;
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> saveToken(String token) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> saveUser(UserEntity user) {
    throw UnimplementedError();
  }
}

class _FakePreferences implements AppPreferences {
  _FakePreferences({this.initialValue});

  final bool? initialValue;

  @override
  bool? readBool(String key) => initialValue;

  @override
  int? readInt(String key) => null;

  @override
  double? readDouble(String key) => null;

  @override
  String? readString(String key) => null;

  @override
  Future<void> writeBool(String key, bool value) async {}

  @override
  Future<void> writeInt(String key, int value) async {}

  @override
  Future<void> writeDouble(String key, double value) async {}

  @override
  Future<void> writeString(String key, String value) async {}
}

class _FakeAppBubbleService implements AppBubbleService {
  @override
  Future<bool> isBubbleRunning() async => false;

  @override
  Future<bool> isOverlayPermissionGranted() async => true;

  @override
  Future<void> openOverlayPermissionSettings() async {}

  @override
  Future<void> startBubble() async {}

  @override
  Future<void> stopBubble() async {}
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(Get.reset);

  testWidgets('renderiza secoes principais, card de perfil e sair da conta', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..storedUser = UserEntity(
        id: 1,
        email: 'samuel@example.com',
        name: 'Samuel Vitor',
        role: 'user',
        isActive: true,
      );

    final preferences = _FakePreferences(initialValue: true);
    final appBubbleService = _FakeAppBubbleService();
    final controller = SettingsController(
      appBubbleService: appBubbleService,
      preferences: preferences,
      getStoredUserUseCase: GetStoredUserUseCase(repository),
      logoutUseCase: LogoutUseCase(repository),
      updateProfilePhotoUseCase: UpdateProfilePhotoUseCase(repository),
    )..onInit();
    Get.put<SettingsController>(controller);

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.dark, home: const SettingsView()),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Ajustes'),
      findsOneWidget,
    ); // O CustomAppBar tem apenas 1 titulo 'Ajustes' renderizado visivelmente.
    expect(find.text('Sem plano ativo'), findsOneWidget);
    expect(find.text('FINANCAS'), findsOneWidget);
    expect(find.text('CATEGORIAS'), findsOneWidget);
    expect(find.text('CONFIGURACOES DE TRABALHO (SEMAFORO)'), findsOneWidget);
    expect(find.text('Configurar gravação'), findsOneWidget);
    expect(find.text('JORNADA E METAS'), findsOneWidget);
    expect(find.text('Sair da conta'), findsOneWidget);
  });

  testWidgets('cta Ver plano navega para rota de assinatura', (tester) async {
    final repository = _FakeAuthRepository();
    final preferences = _FakePreferences(initialValue: true);
    final appBubbleService = _FakeAppBubbleService();
    final controller = SettingsController(
      appBubbleService: appBubbleService,
      preferences: preferences,
      getStoredUserUseCase: GetStoredUserUseCase(repository),
      logoutUseCase: LogoutUseCase(repository),
      updateProfilePhotoUseCase: UpdateProfilePhotoUseCase(repository),
    );
    Get.put<SettingsController>(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        initialRoute: AppRoutes.settings,
        getPages: [
          GetPage(name: AppRoutes.settings, page: () => const SettingsView()),
          GetPage(
            name: AppRoutes.subscription,
            page: () => const Scaffold(body: Text('Subscription Screen')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver plano'));
    await tester.pumpAndSettle();

    expect(find.text('Subscription Screen'), findsOneWidget);
  });
}
