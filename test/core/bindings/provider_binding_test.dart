import 'dart:io';

import 'package:dio/dio.dart';
import 'package:direcao_financeira_mobile/app/core/accessibility/accessibility_controller.dart';
import 'package:direcao_financeira_mobile/app/core/bindings/core_binding.dart';
import 'package:direcao_financeira_mobile/app/core/bindings/provider_binding.dart';
import 'package:direcao_financeira_mobile/app/core/config/app_environment.dart';
import 'package:direcao_financeira_mobile/app/core/network/api_error_mapper.dart';
import 'package:direcao_financeira_mobile/app/core/network/api_request_logger.dart';
import 'package:direcao_financeira_mobile/app/core/network/realtime_client.dart';
import 'package:direcao_financeira_mobile/app/core/session/session_store.dart';
import 'package:direcao_financeira_mobile/app/core/session/user_cache.dart';
import 'package:direcao_financeira_mobile/app/data/datasources/subscription_store_datasource.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_auth_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_journey_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_subscription_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_transaction_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/store_product_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/store_purchase_event_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide RealtimeClient;
import 'package:flutter/services.dart';

class _FakeAccessibilityController extends AccessibilityController {
  _FakeAccessibilityController({required super.storage});

  @override
  Future<void> checkServiceStatus() async {}

  @override
  Future<void> syncSettingsWithNative() async {}

  @override
  Future<void> syncRuntimeStateWithNative() async {}
}

class _FakeSubscriptionStoreDataSource implements ISubscriptionStoreDataSource {
  final Stream<StorePurchaseEventEntity> _emptyStream =
      const Stream<StorePurchaseEventEntity>.empty();

  @override
  Stream<StorePurchaseEventEntity> get purchaseUpdates => _emptyStream;

  @override
  Future<void> buyProduct({
    required String productId,
    String? applicationUserName,
  }) async {}

  @override
  Future<void> completePurchase(String productId) async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<List<StoreProductEntity>> getProductsByIds(
    Set<String> productIds,
  ) async {
    return const [];
  }

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}
}

void main() {
  const storageName = 'provider_binding_test';
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          return Directory.systemTemp.path;
        });
    await GetStorage.init(storageName);
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  setUp(() async {
    Get.reset();
    await GetStorage(storageName).erase();
  });

  tearDown(() async {
    await GetStorage(storageName).erase();
    Get.reset();
  });

  test('provider nest registra dependencias centrais da aplicacao', () {
    final environment = const AppEnvironment(
      backendProvider: BackendProviderKind.nest,
      apiBaseUrl: 'https://example.com',
      supabaseUrl: '',
      supabaseAnonKey: '',
      enableRealtime: false,
    );
    final storage = GetStorage(storageName);

    Get.put<AccessibilityController>(
      _FakeAccessibilityController(storage: storage),
      permanent: true,
    );
    Get.put<ISubscriptionStoreDataSource>(
      _FakeSubscriptionStoreDataSource(),
      permanent: true,
    );

    CoreBinding(environment: environment, storage: storage).dependencies();
    ProviderBinding(environment: environment).dependencies();

    expect(Get.isRegistered<SessionStore>(), isTrue);
    expect(Get.isRegistered<UserCache>(), isTrue);
    expect(Get.isRegistered<ApiErrorMapper>(), isTrue);
    expect(Get.isRegistered<ApiRequestLogger>(), isTrue);
    expect(Get.isRegistered<Dio>(), isTrue);
    expect(Get.isRegistered<RealtimeClient>(), isTrue);
    expect(Get.isRegistered<IAuthRepository>(), isTrue);
    expect(Get.isRegistered<ITransactionRepository>(), isTrue);
    expect(Get.isRegistered<ISubscriptionRepository>(), isTrue);
    expect(Get.isRegistered<IJourneyRepository>(), isTrue);
    expect(Get.find<Dio>().options.baseUrl, 'https://example.com');
  });

  test('provider supabase registra dependencias centrais da aplicacao', () {
    final environment = const AppEnvironment(
      backendProvider: BackendProviderKind.supabase,
      apiBaseUrl: '',
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon-key',
      enableRealtime: false,
    );
    final storage = GetStorage(storageName);

    Get.put<AccessibilityController>(
      _FakeAccessibilityController(storage: storage),
      permanent: true,
    );
    Get.put<ISubscriptionStoreDataSource>(
      _FakeSubscriptionStoreDataSource(),
      permanent: true,
    );
    Get.put<SupabaseClient>(
      SupabaseClient('https://example.supabase.co', 'anon-key'),
      permanent: true,
    );

    CoreBinding(environment: environment, storage: storage).dependencies();
    ProviderBinding(environment: environment).dependencies();

    expect(Get.isRegistered<RealtimeClient>(), isTrue);
    expect(Get.isRegistered<IAuthRepository>(), isTrue);
    expect(Get.isRegistered<ITransactionRepository>(), isTrue);
    expect(Get.isRegistered<ISubscriptionRepository>(), isTrue);
    expect(Get.isRegistered<IJourneyRepository>(), isTrue);
    expect(Get.isRegistered<SupabaseClient>(), isTrue);
  });
}
