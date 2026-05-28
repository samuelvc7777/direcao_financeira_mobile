import '../../domain/entities/help_video_entity.dart';

class HelpVideoModel extends HelpVideoEntity {
  HelpVideoModel({
    required super.id,
    required super.title,
    required super.description,
    required super.youtubeVideoId,
    required super.sortOrder,
    super.category,
    super.durationLabel,
    super.thumbnailUrl,
    super.isFeatured,
  });

  factory HelpVideoModel.fromMap(Map<String, dynamic> map) {
    final youtubeVideoId = _extractYoutubeVideoId(map);
    return HelpVideoModel(
      id: (map['id'] ?? youtubeVideoId).toString(),
      title: (map['title'] ?? map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      youtubeVideoId: youtubeVideoId,
      category: (map['category'] ?? '').toString(),
      durationLabel:
          (map['durationLabel'] ??
                  map['duration_label'] ??
                  map['duration'] ??
                  '')
              .toString(),
      thumbnailUrl:
          (map['thumbnailUrl'] ??
                  map['thumbnail_url'] ??
                  map['thumbnail'] ??
                  '')
              .toString(),
      isFeatured: map['isFeatured'] == true || map['is_featured'] == true,
      sortOrder:
          int.tryParse(
            (map['sortOrder'] ?? map['sort_order'] ?? map['order'] ?? 0)
                .toString(),
          ) ??
          0,
    );
  }

  static String _extractYoutubeVideoId(Map<String, dynamic> map) {
    final explicit = (map['youtubeVideoId'] ?? map['youtube_video_id'] ?? '')
        .toString()
        .trim();
    if (explicit.isNotEmpty) {
      return explicit;
    }

    final rawUrl = (map['url'] ?? map['videoUrl'] ?? map['video_url'] ?? '')
        .toString()
        .trim();
    if (rawUrl.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      return rawUrl;
    }

    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isEmpty ? rawUrl : uri.pathSegments.first;
    }

    final watchId = uri.queryParameters['v'];
    if (watchId != null && watchId.isNotEmpty) {
      return watchId;
    }

    if (uri.pathSegments.contains('embed')) {
      final index = uri.pathSegments.indexOf('embed');
      if (uri.pathSegments.length > index + 1) {
        return uri.pathSegments[index + 1];
      }
    }

    return rawUrl;
  }
}
