import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/google_api_config_entity.dart';

abstract class IGoogleApiConfigRepository {
  Future<Either<Failure, GoogleApiConfigEntity?>> getConfig();
}
