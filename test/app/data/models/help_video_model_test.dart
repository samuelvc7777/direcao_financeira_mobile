import 'package:direcao_financeira_mobile/app/data/models/help_video_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('usa youtubeVideoId explicito', () {
    final model = HelpVideoModel.fromMap({
      'id': 'teste',
      'title': 'Video teste',
      'description': 'Descricao',
      'youtubeVideoId': 'HxgGW_ECu0w',
      'sortOrder': 1,
    });

    expect(model.youtubeVideoId, 'HxgGW_ECu0w');
    expect(model.resolvedThumbnailUrl, contains('HxgGW_ECu0w'));
  });

  test('normaliza url watch do YouTube para id', () {
    final model = HelpVideoModel.fromMap({
      'id': 'teste',
      'title': 'Video teste',
      'url': 'https://www.youtube.com/watch?v=HxgGW_ECu0w',
    });

    expect(model.youtubeVideoId, 'HxgGW_ECu0w');
  });

  test('le campo is_featured vindo do banco', () {
    final model = HelpVideoModel.fromMap({
      'id': 'demo',
      'title': 'Video demonstrativo',
      'youtube_video_id': 'HxgGW_ECu0w',
      'is_featured': true,
      'sort_order': 3,
    });

    expect(model.isFeatured, isTrue);
    expect(model.sortOrder, 3);
  });
}
