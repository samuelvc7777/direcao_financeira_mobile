import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/traffic_light_settings_entity.dart';
import '../../domain/repositories/i_traffic_light_repository.dart';
import '../datasources/traffic_light_local_datasource.dart';
import '../models/traffic_light_settings_model.dart';

class TrafficLightRepositoryImpl implements ITrafficLightRepository {
  final ITrafficLightLocalDataSource localDataSource;

  TrafficLightRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, TrafficLightSettingsEntity>> getSettings() async {
    try {
      final model = await localDataSource.getSettings();
      return Right(model);
    } catch (e) {
      return Left(
        DatabaseFailure('Erro ao carregar configurações do semáforo.'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> saveSettings(
    TrafficLightSettingsEntity settings,
  ) async {
    try {
      final model = TrafficLightSettingsModel.fromEntity(settings);
      await localDataSource.saveSettings(model);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Erro ao salvar configurações do semáforo.'));
    }
  }
}
