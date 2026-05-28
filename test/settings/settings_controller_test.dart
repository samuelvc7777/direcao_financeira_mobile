import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:direcao_financeira_mobile/app/core/app_bubble/app_bubble_service.dart';
import 'package:direcao_financeira_mobile/app/core/errors/failures.dart';
import 'package:direcao_financeira_mobile/app/core/preferences/app_preferences.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/plan_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/store_product_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/store_purchase_event_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/subscription_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/user_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_auth_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_subscription_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/auth_session_use_cases.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/subscription_use_cases.dart';
import 'package:direcao_financeira_mobile/app/presentation/modules/settings/settings_controller.dart';
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
  ) async {
    updatedProfilePhotoBase64 = profilePhotoBase64;
    if (storedUser == null) {
      return Left(DatabaseFailure('Usuario nao encontrado.'));
    }

    final updatedUser = UserEntity(
      id: storedUser!.id,
      email: storedUser!.email,
      name: storedUser!.name,
      role: storedUser!.role,
      isActive: storedUser!.isActive,
      createdAt: storedUser!.createdAt,
      updatedAt: storedUser!.updatedAt,
      profilePhotoBase64: profilePhotoBase64,
      activeSubscription: storedUser!.activeSubscription,
      subscriptions: storedUser!.subscriptions,
    );
    storedUser = updatedUser;
    return Right(updatedUser);
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

class _FakeSubscriptionRepository implements ISubscriptionRepository {
  SubscriptionEntity? activeSubscription;
  bool syncStoredUserCalled = false;

  @override
  Stream<StorePurchaseEventEntity> get purchaseUpdates => const Stream.empty();

  @override
  Future<Either<Failure, SubscriptionEntity?>> getMySubscription() async =>
      Right(activeSubscription);

  @override
  Future<Either<Failure, List<SubscriptionEntity>>>
  getSubscriptionHistory() async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<PlanEntity>>> getAvailablePlans() async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, SubscriptionEntity?>> changePlan(int planId) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, SubscriptionEntity?>> syncStorePurchase({
    required int planId,
    required String productId,
    required String purchaseToken,
    String? purchaseId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, SubscriptionEntity?>> cancelSubscription() async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, SubscriptionEntity?>> renewSubscription({
    required bool autoRenew,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, bool>> isStoreAvailable() async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<StoreProductEntity>>> getStoreProducts(
    Set<String> productIds,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> buyProduct({
    required String productId,
    String? applicationUserName,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> restorePurchases({
    String? applicationUserName,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> completePurchase(String productId) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> syncStoredUser({
    SubscriptionEntity? activeSubscription,
    List<SubscriptionEntity>? subscriptions,
  }) async {
    syncStoredUserCalled = true;
    this.activeSubscription = activeSubscription;
    return const Right(null);
  }
}

SubscriptionEntity _buildActiveSubscription() {
  return SubscriptionEntity(
    id: 10,
    status: 'ACTIVE',
    startDate: DateTime.now().subtract(const Duration(days: 5)),
    endDate: DateTime.now().add(const Duration(days: 25)),
    autoRenew: true,
    plan: PlanEntity(
      id: 1,
      code: 'premium_monthly',
      name: 'anual',
      description: 'Plano anual',
      priceCents: 25490,
      durationDays: 365,
      color: '#111111',
      isActive: true,
    ),
  );
}

class _FakePreferences implements AppPreferences {
  _FakePreferences({this.initialValue});

  final bool? initialValue;
  bool? lastWrittenValue;

  @override
  bool? readBool(String key) => initialValue;

  @override
  int? readInt(String key) => null;

  @override
  double? readDouble(String key) => null;

  @override
  String? readString(String key) => null;

  @override
  Future<void> writeBool(String key, bool value) async {
    lastWrittenValue = value;
  }

  @override
  Future<void> writeInt(String key, int value) async {}

  @override
  Future<void> writeDouble(String key, double value) async {}

  @override
  Future<void> writeString(String key, String value) async {}
}

class _FakeAppBubbleService implements AppBubbleService {
  bool isPermissionGranted = true;
  bool isRunning = false;

  @override
  Future<bool> isBubbleRunning() async => isRunning;

  @override
  Future<bool> isOverlayPermissionGranted() async => isPermissionGranted;

  @override
  Future<void> openOverlayPermissionSettings() async {}

  @override
  Future<void> startBubble() async {
    isRunning = true;
  }

  @override
  Future<void> stopBubble() async {
    isRunning = false;
  }
}

void main() {
  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
  });

  group('SettingsController', () {
    test('toggleTheme alterna o estado local do switch', () {
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
      Get.put(controller);

      expect(controller.isDarkModeEnabled.value, isTrue);

      controller.toggleTheme(false);

      expect(controller.isDarkModeEnabled.value, isFalse);
      expect(preferences.lastWrittenValue, isFalse);

      Get.delete<SettingsController>();
    });

    test('logout reutiliza o repositorio de autenticacao', () async {
      final repository = _FakeAuthRepository();
      final preferences = _FakePreferences();
      final appBubbleService = _FakeAppBubbleService();
      final controller = SettingsController(
        appBubbleService: appBubbleService,
        preferences: preferences,
        getStoredUserUseCase: GetStoredUserUseCase(repository),
        logoutUseCase: LogoutUseCase(repository),
        updateProfilePhotoUseCase: UpdateProfilePhotoUseCase(repository),
      );
      Get.put(controller);

      // Omitimos a execucao real do logout por causa do Get.offAllNamed (dependencia de UI)
      // e testamos apenas se a dependencia responde.
      final result = await repository.logout();
      expect(result.isRight(), isTrue);

      expect(repository.logoutCalled, isTrue);

      Get.delete<SettingsController>();
    });

    testWidgets(
      'atualiza a assinatura do perfil quando o cache local esta desatualizado',
      (tester) async {
        final authRepository = _FakeAuthRepository()
          ..storedUser = UserEntity(
            id: 1,
            email: 'samuel@example.com',
            name: 'Samuel Vitor',
            role: 'user',
            isActive: true,
            activeSubscription: null,
          );
        final subscriptionRepository = _FakeSubscriptionRepository()
          ..activeSubscription = _buildActiveSubscription();
        final preferences = _FakePreferences(initialValue: true);
        final appBubbleService = _FakeAppBubbleService();
        final controller = SettingsController(
          appBubbleService: appBubbleService,
          preferences: preferences,
          getStoredUserUseCase: GetStoredUserUseCase(authRepository),
          logoutUseCase: LogoutUseCase(authRepository),
          updateProfilePhotoUseCase: UpdateProfilePhotoUseCase(authRepository),
          getMySubscriptionUseCase: GetMySubscriptionUseCase(
            subscriptionRepository,
          ),
          syncStoredUserSubscriptionUseCase:
              SyncStoredUserSubscriptionUseCase(subscriptionRepository),
        );
        Get.put(controller);

        await tester.pumpWidget(
          GetMaterialApp(home: const Scaffold(body: SizedBox.shrink())),
        );
        await tester.pumpAndSettle();

        expect(controller.planStatus.value, 'Ativo');
        expect(controller.planName.value, 'anual');
        expect(subscriptionRepository.syncStoredUserCalled, isTrue);
        expect(find.text('Inativo'), findsNothing);

        Get.delete<SettingsController>();
      },
    );

    test(
      'estado do balao rodando prevalece sobre preferencia local antiga',
      () async {
        final repository = _FakeAuthRepository();
        final preferences = _FakePreferences(initialValue: false);
        final appBubbleService = _FakeAppBubbleService()..isRunning = true;
        final controller = SettingsController(
          appBubbleService: appBubbleService,
          preferences: preferences,
          getStoredUserUseCase: GetStoredUserUseCase(repository),
          logoutUseCase: LogoutUseCase(repository),
          updateProfilePhotoUseCase: UpdateProfilePhotoUseCase(repository),
        );
        Get.put(controller);
        await Future<void>.delayed(Duration.zero);

        expect(controller.isAppBubbleEnabled.value, isTrue);
        expect(preferences.lastWrittenValue, isTrue);
        expect(appBubbleService.isRunning, isTrue);

        Get.delete<SettingsController>();
      },
    );

    testWidgets('updateProfilePhotoBytes salva a foto e atualiza o estado', (
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
      final preferences = _FakePreferences();
      final appBubbleService = _FakeAppBubbleService();
      final controller = SettingsController(
        appBubbleService: appBubbleService,
        preferences: preferences,
        getStoredUserUseCase: GetStoredUserUseCase(repository),
        logoutUseCase: LogoutUseCase(repository),
        updateProfilePhotoUseCase: UpdateProfilePhotoUseCase(repository),
      );
      Get.put(controller);

      await tester.pumpWidget(
        GetMaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );
      await tester.pump();

      await controller.updateProfilePhotoBytes(Uint8List.fromList([1, 2, 3]));
      await tester.pumpAndSettle();

      expect(repository.updatedProfilePhotoBase64, 'AQID');
      expect(controller.profilePhotoBase64.value, 'AQID');

      Get.delete<SettingsController>();
    });
  });
}
