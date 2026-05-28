import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/help_support_contact_entity.dart';
import '../entities/help_video_entity.dart';
import '../repositories/i_help_repository.dart';

class LoadHelpVideosUseCase {
  const LoadHelpVideosUseCase(this.repository);

  final IHelpRepository repository;

  Future<Either<Failure, List<HelpVideoEntity>>> call() {
    return repository.getVideos();
  }
}

class GetHelpSupportContactUseCase {
  const GetHelpSupportContactUseCase(this.repository);

  final IHelpRepository repository;

  Future<Either<Failure, HelpSupportContactEntity>> call() {
    return repository.getSupportContact();
  }
}

class OpenHelpSupportContactUseCase {
  const OpenHelpSupportContactUseCase(this.repository);

  final IHelpRepository repository;

  Future<Either<Failure, void>> call() {
    return repository.openSupportContact();
  }
}
