import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';

class YoutubeApiService {
  final Dio dio;

  YoutubeApiService(this.dio);

  Future<List<Map<String, dynamic>>> searchLiveStreams() async {
    try {
      final response = await dio.get(
        '${ApiConstants.youtubeBaseUrl}/search',
        queryParameters: {
          'part': 'snippet',
          'type': 'video',
          'eventType': 'live',
          'q': 'football live stream',
          'key': ApiConstants.youtubeApiKey,
          'maxResults': 10,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> items = response.data['items'];
        return items.map((item) => item as Map<String, dynamic>).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
