class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String image;
  final String source;
  final String publishedAt;

  const NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    this.image = '',
    required this.source,
    required this.publishedAt,
  });

  /// Human-friendly time-ago label
  String get timeAgo {
    try {
      final pub = DateTime.parse(publishedAt);
      final diff = DateTime.now().difference(pub);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)   return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}
