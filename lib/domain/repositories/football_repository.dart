import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/fixture.dart';
import '../entities/statistic.dart';
import '../entities/lineup.dart';
import '../entities/standing.dart';

import '../entities/match_event.dart';

abstract class FootballRepository {
  Future<Either<Failure, List<Fixture>>> getLiveFixtures();
  Future<Either<Failure, List<Fixture>>> getFixturesByDate(DateTime date);
  Future<Either<Failure, List<Statistic>>> getFixtureStatistics(int fixtureId);
  Future<Either<Failure, List<Lineup>>> getFixtureLineups(int fixtureId);
  Future<Either<Failure, List<Standing>>> getLeagueStandings(int leagueId, int season);
  Future<Either<Failure, List<MatchEvent>>> getFixtureEvents(int fixtureId);
  Future<Either<Failure, List<Fixture>>> getHeadToHead(int homeTeamId, int awayTeamId);
}
