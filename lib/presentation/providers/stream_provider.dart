import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/live_stream_channel.dart';
import '../../data/datasources/remote/stream_api_service.dart';
import 'youtube_provider.dart';
import 'fixture_provider.dart';

final streamApiServiceProvider = Provider<StreamApiService>((ref) {
  return StreamApiService(
    dio: ref.read(dioProvider),
    youtubeService: ref.read(youtubeApiServiceProvider),
  );
});

class CustomStreamsNotifier extends StateNotifier<List<LiveStreamChannel>> {
  CustomStreamsNotifier() : super([]);

  void addCustomStream(String title, String url) {
    final newStream = LiveStreamChannel(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      competition: 'Custom Stream Feed',
      thumbnailUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800',
      date: 'Live Feed',
      primaryStreamUrl: url,
      isLive: true,
      servers: [
        StreamServer(name: 'Direct Stream (Server 1)', url: url),
      ],
    );
    state = [newStream, ...state];
  }
}

final customStreamsProvider = StateNotifierProvider<CustomStreamsNotifier, List<LiveStreamChannel>>((ref) {
  return CustomStreamsNotifier();
});

final allStreamsProvider = FutureProvider<List<LiveStreamChannel>>((ref) async {
  final api = ref.read(streamApiServiceProvider);
  final curated = await api.getAllStreams();
  final custom = ref.watch(customStreamsProvider);
  return [...custom, ...curated];
});
