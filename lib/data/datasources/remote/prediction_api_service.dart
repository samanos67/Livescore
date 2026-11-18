import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/match_prediction_model.dart';

class PredictionApiService {
  final Dio dio;

  PredictionApiService(this.dio);

  String get _base => ApiConstants.backendUrl;

  Future<MatchPredictionModel> getPredictionForFixture(int fixtureId) async {
    try {
      final response = await dio.get(
        '$_base/predictions/$fixtureId',
        options: Options(receiveTimeout: const Duration(seconds: 15)),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['response'];
        if (data is Map<String, dynamic>) {
          return MatchPredictionModel.fromJson(data);
        }
      }
      throw ServerException();
    } on DioException catch (e) {
      // ignore: avoid_print
      print('[PredictionApiService] Error: $e');
      throw ServerException();
    } catch (_) {
      throw ServerException();
    }
  }

  Future<List<MatchPredictionModel>> getTodayPredictions() async {
    try {
      final response = await dio.get(
        '$_base/predictions/today',
        options: Options(receiveTimeout: const Duration(seconds: 20)),
      );

      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data['response'] as List?) ?? [];
        final results = <MatchPredictionModel>[];
        for (final item in list) {
          if (item is Map) {
            results.add(MatchPredictionModel.fromJson(Map<String, dynamic>.from(item)));
          }
        }
        return results;
      }
      return [];
    } on DioException catch (e) {
      // ignore: avoid_print
      print('[PredictionApiService] Error fetching today predictions: $e');
      throw ServerException();
    } catch (_) {
      throw ServerException();
    }
  }
}
