import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../core/errors/failures.dart';
import '../../core/network/api_error_mapper.dart';
import '../../core/network/api_request_logger.dart';
import '../../domain/entities/plan_entity.dart';
import '../../domain/entities/store_product_entity.dart';
import '../../domain/entities/store_purchase_event_entity.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/i_subscription_repository.dart';
import '../datasources/subscription_datasource.dart';
import '../datasources/subscription_store_datasource.dart';

class SubscriptionRepository implements ISubscriptionRepository {
  SubscriptionRepository({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.storeDataSource,
    required this.apiErrorMapper,
    required this.apiRequestLogger,
  });

  final ISubscriptionRemoteDataSource remoteDataSource;
  final ISubscriptionLocalDataSource localDataSource;
  final ISubscriptionStoreDataSource storeDataSource;
  final ApiErrorMapper apiErrorMapper;
  final ApiRequestLogger apiRequestLogger;

  @override
  Stream<StorePurchaseEventEntity> get purchaseUpdates =>
      storeDataSource.purchaseUpdates;

  @override
  Future<Either<Failure, SubscriptionEntity?>> getMySubscription() async {
    try {
      return Right(await remoteDataSource.getMySubscription());
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'SubscriptionRepository.getMySubscription',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao carregar assinatura.',
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'SubscriptionRepository.getMySubscription',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao carregar assinatura.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<SubscriptionEntity>>>
  getSubscriptionHistory() async {
    try {
      return Right(await remoteDataSource.getSubscriptionHistory());
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'SubscriptionRepository.getSubscriptionHistory',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(e, fallback: 'Erro ao carregar historico.'),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'SubscriptionRepository.getSubscriptionHistory',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao carregar historico.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<PlanEntity>>> getAvailablePlans() async {
    try {
      return Right(await remoteDataSource.getAvailablePlans());
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'SubscriptionRepository.getAvailablePlans',
        error: e,
      );
      if (e.response?.statusCode == 404) {
        return const Right([]);
      }
      return Left(
        apiErrorMapper.mapToFailure(e, fallback: 'Erro ao carregar planos.'),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'SubscriptionRepository.getAvailablePlans',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao carregar planos.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, SubscriptionEntity?>> changePlan(int planId) async {
    try {
      return Right(await remoteDataSource.changePlan(planId));
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'SubscriptionRepository.changePlan',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(e, fallback: 'Erro ao trocar o plano.'),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'SubscriptionRepository.changePlan',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao trocar o plano.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, SubscriptionEntity?>> syncStorePurchase({
    required int planId,
    required String productId,
    required String purchaseToken,
    String? purchaseId,
  }) async {
    try {
      return Right(
        await remoteDataSource.syncStorePurchase(
          planId: planId,
          productId: productId,
          purchaseToken: purchaseToken,
          purchaseId: purchaseId,
        ),
      );
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'SubscriptionRepository.syncStorePurchase',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao sincronizar compra da Play Store.',
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'SubscriptionRepository.syncStorePurchase',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao sincronizar compra da Play Store.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, SubscriptionEntity?>> cancelSubscription() async {
    try {
      return Right(await remoteDataSource.cancelSubscription());
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'SubscriptionRepository.cancelSubscription',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro ao cancelar assinatura.',
        ),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'SubscriptionRepository.cancelSubscription',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao cancelar assinatura.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, SubscriptionEntity?>> renewSubscription({
    required bool autoRenew,
  }) async {
    try {
      return Right(
        await remoteDataSource.renewSubscription(autoRenew: autoRenew),
      );
    } on DioException catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'SubscriptionRepository.renewSubscription',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(e, fallback: 'Erro ao renovar assinatura.'),
      );
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'SubscriptionRepository.renewSubscription',
        error: e,
      );
      return Left(
        apiErrorMapper.mapToFailure(
          e,
          fallback: 'Erro inesperado ao renovar assinatura.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> isStoreAvailable() async {
    try {
      return Right(await storeDataSource.isAvailable());
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'SubscriptionRepository.isStoreAvailable',
        error: e,
      );
      return Left(
        ServerFailure('Erro ao verificar disponibilidade da Play Store.'),
      );
    }
  }

  @override
  Future<Either<Failure, List<StoreProductEntity>>> getStoreProducts(
    Set<String> productIds,
  ) async {
    try {
      return Right(await storeDataSource.getProductsByIds(productIds));
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'SubscriptionRepository.getStoreProducts',
        error: e,
      );
      return Left(ServerFailure('Erro ao carregar produtos da Play Store.'));
    }
  }

  @override
  Future<Either<Failure, void>> buyProduct({
    required String productId,
    String? applicationUserName,
  }) async {
    try {
      await storeDataSource.buyProduct(
        productId: productId,
        applicationUserName: applicationUserName,
      );
      return const Right(null);
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'SubscriptionRepository.buyProduct',
        error: e,
      );
      return Left(ServerFailure(e.toString().replaceFirst('Bad state: ', '')));
    }
  }

  @override
  Future<Either<Failure, void>> restorePurchases({
    String? applicationUserName,
  }) async {
    try {
      await storeDataSource.restorePurchases(
        applicationUserName: applicationUserName,
      );
      return const Right(null);
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'SubscriptionRepository.restorePurchases',
        error: e,
      );
      return Left(ServerFailure('Erro ao restaurar compras da Play Store.'));
    }
  }

  @override
  Future<Either<Failure, void>> completePurchase(String productId) async {
    try {
      await storeDataSource.completePurchase(productId);
      return const Right(null);
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'SubscriptionRepository.completePurchase',
        error: e,
      );
      return Left(ServerFailure('Erro ao finalizar a compra na Play Store.'));
    }
  }

  @override
  Future<Either<Failure, void>> syncStoredUser({
    SubscriptionEntity? activeSubscription,
    List<SubscriptionEntity>? subscriptions,
  }) async {
    try {
      await localDataSource.syncStoredUser(
        activeSubscription: activeSubscription,
        subscriptions: subscriptions,
      );
      return const Right(null);
    } catch (e) {
      apiRequestLogger.logRepositoryFailure(
        source: 'SubscriptionRepository.syncStoredUser',
        error: e,
      );
      return Left(DatabaseFailure('Erro ao sincronizar dados do usuario.'));
    }
  }
}
