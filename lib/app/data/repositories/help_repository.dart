import 'package:dartz/dartz.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/errors/failures.dart';
import '../../core/network/api_error_mapper.dart';
import '../../core/network/api_request_logger.dart';
import '../../domain/entities/help_support_contact_entity.dart';
import '../../domain/entities/help_video_entity.dart';
import '../../domain/repositories/i_help_repository.dart';
import '../datasources/help_video_datasource.dart';

class HelpRepository implements IHelpRepository {
  const HelpRepository({
    required this.dataSource,
    required this.apiErrorMapper,
    required this.apiRequestLogger,
  });

  final IHelpVideoDataSource dataSource;
  final ApiErrorMapper apiErrorMapper;
  final ApiRequestLogger apiRequestLogger;

  @override
  Future<Either<Failure, List<HelpVideoEntity>>> getVideos() async {
    try {
      return Right(await dataSource.getVideos());
    } catch (error) {
      return Left(
        _mapFailure(
          'HelpRepository.getVideos',
          error,
          'Nao foi possivel carregar os videos de ajuda.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, HelpSupportContactEntity>> getSupportContact() async {
    try {
      return Right(await dataSource.getSupportContact());
    } catch (error) {
      return Left(
        _mapFailure(
          'HelpRepository.getSupportContact',
          error,
          'Nao foi possivel carregar o contato de suporte.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> openSupportContact() async {
    final contactResult = await getSupportContact();
    return contactResult.fold(Left.new, (contact) async {
      final uri = contact.toUri();
      if (uri == null) {
        return Left(
          ValidationFailure('O WhatsApp de suporte ainda nao foi configurado.'),
        );
      }

      try {
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!opened) {
          return Left(
            ServerFailure('Nao foi possivel abrir o WhatsApp neste momento.'),
          );
        }

        return const Right(null);
      } catch (error) {
        return Left(
          _mapFailure(
            'HelpRepository.openSupportContact',
            error,
            'Nao foi possivel abrir o WhatsApp neste momento.',
          ),
        );
      }
    });
  }

  Failure _mapFailure(String source, Object error, String fallback) {
    apiRequestLogger.logRepositoryFailure(source: source, error: error);
    return apiErrorMapper.mapToFailure(error, fallback: fallback);
  }
}
