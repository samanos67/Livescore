import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/match_prediction.dart';

abstract class PredictionRepository {
  Future<Either<Failure, MatchPrediction>> getPredictionForFixture(int fixtureId);
  Future<Either<Failure, List<MatchPrediction>>> getTodayPredictions();
}
