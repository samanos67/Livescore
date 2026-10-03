import 'package:dio/dio.dart';
import '../../../domain/entities/live_stream_channel.dart';
import 'youtube_api_service.dart';

class StreamApiService {
  final Dio dio;
  final YoutubeApiService youtubeService;

  StreamApiService({required this.dio, required this.youtubeService});

  // Curated list of high-availability legal & official football streaming channels
  static final List<LiveStreamChannel> _curatedChannels = [
    const LiveStreamChannel(
      id: 'fifa-plus',
      title: 'FIFA+ Live Football Matches',
      competition: 'FIFA Official Live',
      thumbnailUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800&auto=format&fit=crop&q=60',
      date: 'Live 24/7',
      primaryStreamUrl: 'https://www.plus.fifa.com',
      isLive: true,
      servers: [
        StreamServer(
          name: 'FIFA+ Official (Server 1)',
          url: 'https://www.plus.fifa.com',
        ),
      ],
    ),
    const LiveStreamChannel(
      id: 'cbs-golazo',
      title: 'CBS Golazo Live Football Network',
      competition: 'UEFA & International Football',
      thumbnailUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800&auto=format&fit=crop&q=60',
      date: 'Live 24/7',
      primaryStreamUrl: 'https://www.cbssports.com/watch/cbs-sports-golazo-network',
      isLive: true,
      servers: [
        StreamServer(
          name: 'CBS Golazo HD (Server 1)',
          url: 'https://www.cbssports.com/watch/cbs-sports-golazo-network',
        ),
      ],
    ),
    const LiveStreamChannel(
      id: 'rm-tv',
      title: 'Real Madrid TV Live',
      competition: 'La Liga & Champions League Archive',
      thumbnailUrl: 'https://images.unsplash.com/photo-1522778119026-d647f0596c20?w=800&auto=format&fit=crop&q=60',
      date: 'Live Stream',
      primaryStreamUrl: 'https://www.realmadrid.com/en-US/real-madrid-tv',
      isLive: true,
      servers: [
        StreamServer(
          name: 'RMTV Live (Server 1)',
          url: 'https://www.realmadrid.com/en-US/real-madrid-tv',
        ),
      ],
    ),
    const LiveStreamChannel(
      id: 'redbull-sports',
      title: 'Red Bull TV Live Sports Hub',
      competition: 'Live Global Football & Extreme Sports',
      thumbnailUrl: 'https://images.unsplash.com/photo-1517466787929-bc90951d0974?w=800&auto=format&fit=crop&q=60',
      date: 'Live Now',
      primaryStreamUrl: 'https://www.redbull.com/int-en/live-events',
      isLive: true,
      servers: [
        StreamServer(
          name: 'Red Bull Stream (Server 1)',
          url: 'https://www.redbull.com/int-en/live-events',
        ),
      ],
    ),
  ];

  Future<List<LiveStreamChannel>> getAllStreams() async {
    final List<LiveStreamChannel> results = List.from(_curatedChannels);

    // Also fetch live football broadcasts from YouTube if quota is available
    try {
      final ytItems = await youtubeService.searchLiveStreams();
      for (var item in ytItems) {
        final snippet = item['snippet'];
        final id = item['id'];
        final videoId = id is Map ? id['videoId']?.toString() : null;
        if (videoId != null && snippet is Map) {
          final title = snippet['title']?.toString() ?? 'Football Live Stream';
          final channelTitle = snippet['channelTitle']?.toString() ?? 'Live Broadcast';
          final thumb = snippet['thumbnails']?['high']?['url']?.toString() ??
              'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800';

          results.add(
            LiveStreamChannel(
              id: 'yt-$videoId',
              title: title,
              competition: channelTitle,
              thumbnailUrl: thumb,
              date: 'Live on YouTube',
              primaryStreamUrl: 'https://www.youtube.com/watch?v=$videoId',
              isLive: true,
              servers: [
                StreamServer(
                  name: 'YouTube Stream',
                  url: videoId, // Recognized by YouTube player
                ),
                StreamServer(
                  name: 'Web Stream Mirror',
                  url: 'https://www.youtube.com/watch?v=$videoId',
                ),
              ],
            ),
          );
        }
      }
    } catch (_) {}

    return results;
  }
}
