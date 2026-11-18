import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/match_prediction.dart';
import '../../domain/repositories/prediction_repository.dart';
import '../../data/datasources/remote/prediction_api_service.dart';
import '../../data/repositories/prediction_repository_impl.dart';
import 'fixture_provider.dart';

final predictionApiServiceProvider = Provider<PredictionApiService>((ref) {
  return PredictionApiService(ref.read(dioProvider));
});

final predictionRepositoryProvider = Provider<PredictionRepository>((ref) {
  return PredictionRepositoryImpl(ref.read(predictionApiServiceProvider));
});

/// Fetches detailed AI prediction for a specific fixture
final fixturePredictionProvider = FutureProvider.family<MatchPrediction, int>((ref, fixtureId) async {
  final repo = ref.read(predictionRepositoryProvider);
  final result = await repo.getPredictionForFixture(fixtureId);
  return result.fold(
    (failure) => throw failure.message,
    (prediction) => prediction,
  );
});

/// Fetches today's top match predictions
final todayPredictionsProvider = FutureProvider<List<MatchPrediction>>((ref) async {
  final repo = ref.read(predictionRepositoryProvider);
  final result = await repo.getTodayPredictions();
  return result.fold(
    (failure) => throw failure.message,
    (list) => list,
  );
});

/// Tracks fixture IDs whose full tactical analysis has been unlocked via AdMob Rewarded Ad
final unlockedPredictionsProvider = StateProvider<Set<int>>((ref) {
  return <int>{};
});
