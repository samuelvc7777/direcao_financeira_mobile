import 'package:direcao_financeira_mobile/app/core/errors/failures.dart';
import 'package:direcao_financeira_mobile/app/core/network/api_error_mapper.dart';
import 'package:direcao_financeira_mobile/app/core/network/api_request_logger.dart';
import 'package:direcao_financeira_mobile/app/data/datasources/subscription_datasource.dart';
import 'package:direcao_financeira_mobile/app/data/datasources/subscription_store_datasource.dart';
import 'package:direcao_financeira_mobile/app/data/models/plan_model.dart';
import 'package:direcao_financeira_mobile/app/data/models/subscription_model.dart';
import 'package:direcao_financeira_mobile/app/data/repositories/subscription_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/store_product_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/store_purchase_event_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/subscription_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/dio_test_helpers.dart';
import '../../support/test_entities.dart';

class _FakeSubscriptionRemoteDataSource
    implements ISubscriptionRemoteDataSource {
  SubscriptionModel? activeSubscription;
  List<SubscriptionModel> history = [];
  List<PlanModel> plans = [];
  Object? error;

  @override
  Future<SubscriptionModel?> cancelSubscription() async {
    if (error != null) {
      throw error!;
    }
    return activeSubscription;
  }

  @override
  Future<SubscriptionModel?> changePlan(int planId) async {
    if (error != null) {
      throw error!;
    }
    return activeSubscription;
  }

  @override
  Future<SubscriptionModel?> syncStorePurchase({
    required int planId,
    required String productId,
    required String purchaseToken,
    String? purchaseId,
  }) async {
    if (error != null) {
      throw error!;
    }
    return activeSubscription;
  }

  @override
  Future<List<PlanModel>> getAvailablePlans() async {
    if (error != null) {
      throw error!;
    }
    return plans;
  }

  @override
  Future<SubscriptionModel?> getMySubscription() async {
    if (error != null) {
      throw error!;
    }
    return activeSubscription;
  }

  @override
  Future<List<SubscriptionModel>> getSubscriptionHistory() async {
    if (error != null) {
      throw error!;
    }
    return history;
  }

  @override
  Future<SubscriptionModel?> renewSubscription({
    required bool autoRenew,
  }) async {
    if (error != null) {
      throw error!;
    }
    return activeSubscription;
  }
}

class _FakeSubscriptionLocalDataSource implements ISubscriptionLocalDataSource {
  SubscriptionEntity? syncedActiveSubscription;
  List<SubscriptionEntity>? syncedSubscriptions;

  @override
  Future<void> syncStoredUser({
    SubscriptionEntity? activeSubscription,
    List<SubscriptionEntity>? subscriptions,
  }) async {
    syncedActiveSubscription = activeSubscription;
    syncedSubscriptions = subscriptions;
  }
}

class _FakeSubscriptionStoreDataSource implements ISubscriptionStoreDataSource {
  bool available = true;
  List<StoreProductEntity> products = [];

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
    return products
        .where((product) => productIds.contains(product.productId))
        .toList();
  }

  @override
  Future<bool> isAvailable() async => available;

  @override
  Stream<StorePurchaseEventEntity> get purchaseUpdates =>
      const Stream<StorePurchaseEventEntity>.empty();

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}
}

void main() {
  late _FakeSubscriptionRemoteDataSource remoteDataSource;
  late _FakeSubscriptionLocalDataSource localDataSource;
  late _FakeSubscriptionStoreDataSource storeDataSource;
  late SubscriptionRepository repository;

  setUp(() {
    remoteDataSource = _FakeSubscriptionRemoteDataSource()
      ..activeSubscription = buildSubscription()
      ..history = [buildSubscription()]
      ..plans = [buildPlan()];
    localDataSource = _FakeSubscriptionLocalDataSource();
    storeDataSource = _FakeSubscriptionStoreDataSource()
      ..products = [buildStoreProduct()];
    repository = SubscriptionRepository(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      storeDataSource: storeDataSource,
      apiErrorMapper: const ApiErrorMapper(),
      apiRequestLogger: ApiRequestLogger(
        apiErrorMapper: const ApiErrorMapper(),
      ),
    );
  });

  test('getMySubscription retorna assinatura em caso de sucesso', () async {
    final result = await repository.getMySubscription();
    expect(result.isRight(), isTrue);
  });

  test('getMySubscription usa message da API quando disponivel', () async {
    remoteDataSource.error = dioBadResponse(
      statusCode: 400,
      data: {'message': 'Assinatura invalida'},
      path: '/subscriptions/me',
    );

    final result = await repository.getMySubscription();

    expect(
      result.swap().getOrElse(() => ServerFailure('x')).message,
      'Assinatura invalida',
    );
  });

  test(
    'getMySubscription usa fallback quando a API nao envia message',
    () async {
      remoteDataSource.error = dioBadResponse(
        statusCode: 500,
        data: {'error': 'boom'},
        path: '/subscriptions/me',
      );

      final result = await repository.getMySubscription();

      expect(
        result.swap().getOrElse(() => ServerFailure('x')).message,
        'Erro ao carregar assinatura.',
      );
    },
  );

  test('getMySubscription trata falha inesperada', () async {
    remoteDataSource.error = Exception('erro inesperado');

    final result = await repository.getMySubscription();

    expect(
      result.swap().getOrElse(() => ServerFailure('x')).message,
      'Erro inesperado ao carregar assinatura.',
    );
  });

  test('getStoreProducts retorna catalogo da Play Store', () async {
    final result = await repository.getStoreProducts({'premium_monthly'});

    expect(result.isRight(), isTrue);
    expect(
      result.getOrElse(() => const []).single.productId,
      'premium_monthly',
    );
  });
}
