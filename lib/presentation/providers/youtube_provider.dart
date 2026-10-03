import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/youtube_api_service.dart';
import 'fixture_provider.dart'; // To access dioProvider

final youtubeApiServiceProvider = Provider<YoutubeApiService>((ref) {
  return YoutubeApiService(ref.read(dioProvider));
});

final liveStreamsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(youtubeApiServiceProvider);
  return await service.searchLiveStreams();
});
