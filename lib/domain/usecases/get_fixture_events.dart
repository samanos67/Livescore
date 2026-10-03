import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/match_event.dart';
import '../repositories/football_repository.dart';

class GetFixtureEvents {
  final FootballRepository repository;

  GetFixtureEvents(this.repository);

  Future<Either<Failure, List<MatchEvent>>> call(int fixtureId) async {
    return await repository.getFixtureEvents(fixtureId);
  }
}
