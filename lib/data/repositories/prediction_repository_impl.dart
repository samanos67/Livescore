import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/match_prediction.dart';
import '../../domain/repositories/prediction_repository.dart';
import '../datasources/remote/prediction_api_service.dart';

class _CacheEntry<T> {
  final T data;
  final DateTime expiry;
  _CacheEntry(this.data, Duration ttl) : expiry = DateTime.now().add(ttl);
  bool get isExpired => DateTime.now().isAfter(expiry);
}

class PredictionRepositoryImpl implements PredictionRepository {
  final PredictionApiService remoteDataSource;

  static final Map<int, _CacheEntry<MatchPrediction>> _fixtureCache = {};
  static _CacheEntry<List<MatchPrediction>>? _todayCache;

  static const Duration _predictionTtl = Duration(minutes: 30);

  PredictionRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, MatchPrediction>> getPredictionForFixture(int fixtureId) async {
    final cached = _fixtureCache[fixtureId];
    if (cached != null && !cached.isExpired) {
      return Right(cached.data);
    }

    try {
      final prediction = await remoteDataSource.getPredictionForFixture(fixtureId);
      _fixtureCache[fixtureId] = _CacheEntry(prediction, _predictionTtl);
      return Right(prediction);
    } on ServerException {
      return const Left(ServerFailure('Could not generate AI prediction for this fixture.'));
    } catch (e) {
      return Left(NetworkFailure('Network Error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MatchPrediction>>> getTodayPredictions() async {
    final cached = _todayCache;
    if (cached != null && !cached.isExpired) {
      return Right(cached.data);
    }

    try {
      final list = await remoteDataSource.getTodayPredictions();
      if (list.isNotEmpty) {
        _todayCache = _CacheEntry(list, _predictionTtl);
      }
      return Right(list);
    } on ServerException {
      return const Left(ServerFailure('Could not fetch predictions for today.'));
    } catch (e) {
      return Left(NetworkFailure('Network Error: $e'));
    }
  }
}
