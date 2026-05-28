class HelpVideoEntity {
  HelpVideoEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeVideoId,
    required this.sortOrder,
    this.category = '',
    this.durationLabel = '',
    this.thumbnailUrl = '',
    this.isFeatured = false,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError('O id do video de ajuda nao pode ser vazio.');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError('O titulo do video de ajuda nao pode ser vazio.');
    }
    if (youtubeVideoId.trim().isEmpty) {
      throw ArgumentError('O ID do video do YouTube nao pode ser vazio.');
    }
  }

  final String id;
  final String title;
  final String description;
  final String youtubeVideoId;
  final String category;
  final String durationLabel;
  final String thumbnailUrl;
  final bool isFeatured;
  final int sortOrder;

  String get resolvedThumbnailUrl {
    final customThumbnail = thumbnailUrl.trim();
    if (customThumbnail.isNotEmpty) {
      return customThumbnail;
    }

    return 'https://img.youtube.com/vi/$youtubeVideoId/hqdefault.jpg';
  }
}
