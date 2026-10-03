import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/statistic.dart';
import '../repositories/football_repository.dart';

class GetFixtureStatistics {
  final FootballRepository repository;

  GetFixtureStatistics(this.repository);

  Future<Either<Failure, List<Statistic>>> call(int fixtureId) async {
    return await repository.getFixtureStatistics(fixtureId);
  }
}
