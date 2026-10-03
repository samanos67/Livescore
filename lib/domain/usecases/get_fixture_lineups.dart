import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/lineup.dart';
import '../repositories/football_repository.dart';

class GetFixtureLineups {
  final FootballRepository repository;

  GetFixtureLineups(this.repository);

  Future<Either<Failure, List<Lineup>>> call(int fixtureId) async {
    return await repository.getFixtureLineups(fixtureId);
  }
}
