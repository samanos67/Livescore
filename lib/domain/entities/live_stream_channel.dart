import 'package:equatable/equatable.dart';

class StreamServer extends Equatable {
  final String name;
  final String url;
  final bool isDirectVideo; // true if m3u8/mp4, false if web embed

  const StreamServer({
    required this.name,
    required this.url,
    this.isDirectVideo = false,
  });

  @override
  List<Object?> get props => [name, url, isDirectVideo];
}

class LiveStreamChannel extends Equatable {
  final String id;
  final String title;
  final String competition;
  final String thumbnailUrl;
  final String date;
  final String? embedHtml;
  final String primaryStreamUrl;
  final List<StreamServer> servers;
  final bool isLive;

  const LiveStreamChannel({
    required this.id,
    required this.title,
    required this.competition,
    required this.thumbnailUrl,
    required this.date,
    this.embedHtml,
    required this.primaryStreamUrl,
    required this.servers,
    this.isLive = false,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        competition,
        thumbnailUrl,
        date,
        primaryStreamUrl,
        isLive,
      ];
}
