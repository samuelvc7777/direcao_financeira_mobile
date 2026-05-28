import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/help_support_contact_entity.dart';
import '../entities/help_video_entity.dart';

abstract class IHelpRepository {
  Future<Either<Failure, List<HelpVideoEntity>>> getVideos();

  Future<Either<Failure, HelpSupportContactEntity>> getSupportContact();

  Future<Either<Failure, void>> openSupportContact();
}
