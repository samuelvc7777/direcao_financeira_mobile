import 'package:dartz/dartz.dart';
import 'package:direcao_financeira_mobile/app/core/errors/failures.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/help_support_contact_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/help_video_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_help_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/help_use_cases.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHelpRepository implements IHelpRepository {
  _FakeHelpRepository(this.videos);

  final List<HelpVideoEntity> videos;

  @override
  Future<Either<Failure, List<HelpVideoEntity>>> getVideos() async {
    return Right(videos);
  }

  @override
  Future<Either<Failure, HelpSupportContactEntity>> getSupportContact() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> openSupportContact() {
    throw UnimplementedError();
  }
}

void main() {
  HelpVideoEntity video({
    required String id,
    required int sortOrder,
    bool isFeatured = false,
  }) {
    return HelpVideoEntity(
      id: id,
      title: 'Video $id',
      description: 'Descricao $id',
      youtubeVideoId: 'HxgGW_ECu0w',
      sortOrder: sortOrder,
      isFeatured: isFeatured,
    );
  }

  test('retorna video marcado como destaque', () async {
    final useCase = LoadFeaturedHelpVideoUseCase(
      _FakeHelpRepository([
        video(id: 'primeiro', sortOrder: 0),
        video(id: 'destaque', sortOrder: 1, isFeatured: true),
      ]),
    );

    final result = await useCase();

    expect(result.getOrElse(() => null)?.id, 'destaque');
  });

  test('usa primeiro video quando nenhum esta marcado como destaque', () async {
    final useCase = LoadFeaturedHelpVideoUseCase(
      _FakeHelpRepository([
        video(id: 'primeiro', sortOrder: 0),
        video(id: 'segundo', sortOrder: 1),
      ]),
    );

    final result = await useCase();

    expect(result.getOrElse(() => null)?.id, 'primeiro');
  });

  test('retorna null quando nao ha videos', () async {
    final useCase = LoadFeaturedHelpVideoUseCase(_FakeHelpRepository([]));

    final result = await useCase();

    expect(result.getOrElse(() => video(id: 'fallback', sortOrder: 0)), isNull);
  });
}
