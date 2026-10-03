import 'package:dartz/dartz.dart';
import 'package:intl/intl.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/fixture.dart';
import '../../domain/entities/statistic.dart';
import '../../domain/entities/lineup.dart';
import '../../domain/entities/standing.dart';
import '../../domain/entities/match_event.dart';
import '../../domain/repositories/football_repository.dart';
import '../datasources/remote/football_api_service.dart';
import '../datasources/remote/the_sports_db_service.dart';

class FootballRepositoryImpl implements FootballRepository {
  final FootballApiService remoteDataSource;
  final TheSportsDbService? sportsDbDataSource; // kept for compatibility

  // ─── In-App Cache Layer ──────────────────────────────────────────────────
  // These cache at the Flutter layer to avoid re-parsing on screen rebuilds.
  // Backend has its own server-side cache; this is a second fast layer.
  static final Map<String, _CacheEntry<List<Standing>>> _standingsCache = {};
  static final Map<String, _CacheEntry<List<Fixture>>>  _fixturesDateCache = {};

  static const Duration _standingsTtl = Duration(hours: 1);
  static const Duration _fixtureTtl   = Duration(minutes: 30);

  FootballRepositoryImpl(this.remoteDataSource, [this.sportsDbDataSource]);

  // ─── Live Fixtures ────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<Fixture>>> getLiveFixtures() async {
    try {
      final fixtures = await remoteDataSource.getLiveFixtures();
      return Right(fixtures);
    } on ServerException {
      return const Left(ServerFailure('Could not fetch live matches. Check your connection.'));
    } catch (e) {
      return Left(NetworkFailure('Network Error: ${e.runtimeType}'));
    }
  }

  // ─── Fixtures by Date ─────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<Fixture>>> getFixturesByDate(DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final cacheKey = dateStr;

    final entry = _fixturesDateCache[cacheKey];
    if (entry != null && !entry.isExpired) {
      return Right(entry.data);
    }

    try {
      final fixtures = await remoteDataSource.getFixturesByDate(dateStr);
      if (fixtures.isNotEmpty) {
        _fixturesDateCache[cacheKey] = _CacheEntry(fixtures, _fixtureTtl);
      }
      return Right(fixtures);
    } on ServerException {
      if (entry != null) return Right(entry.data); // serve stale on error
      return const Left(ServerFailure('Could not load fixtures.'));
    } catch (e) {
      if (entry != null) return Right(entry.data);
      return Left(NetworkFailure('Network Error: ${e.runtimeType}'));
    }
  }

  // ─── Statistics ───────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<Statistic>>> getFixtureStatistics(int fixtureId) async {
    try {
      final stats = await remoteDataSource.getFixtureStatistics(fixtureId);
      return Right(stats);
    } on ServerException {
      return const Left(ServerFailure('Could not load match statistics.'));
    } catch (e) {
      return const Right([]); // non-critical, return empty gracefully
    }
  }

  // ─── Lineups ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<Lineup>>> getFixtureLineups(int fixtureId) async {
    try {
      final lineups = await remoteDataSource.getFixtureLineups(fixtureId);
      return Right(lineups);
    } on ServerException {
      return const Left(ServerFailure('Could not load lineups.'));
    } catch (e) {
      return const Right([]);
    }
  }

  // ─── Standings ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<Standing>>> getLeagueStandings(int leagueId, int season) async {
    final cacheKey = '$leagueId-$season';

    final entry = _standingsCache[cacheKey];
    if (entry != null && !entry.isExpired) {
      return Right(entry.data);
    }

    try {
      final standings = await remoteDataSource.getLeagueStandings(leagueId, season);
      if (standings.isNotEmpty) {
        _standingsCache[cacheKey] = _CacheEntry(standings, _standingsTtl);
      }
      return Right(standings);
    } on ServerException {
      if (entry != null) return Right(entry.data);
      return const Left(ServerFailure('Could not load standings.'));
    } catch (e) {
      if (entry != null) return Right(entry.data);
      return Left(NetworkFailure('Network Error: ${e.runtimeType}'));
    }
  }

  // ─── Events / Timeline ────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<MatchEvent>>> getFixtureEvents(int fixtureId) async {
    try {
      final events = await remoteDataSource.getFixtureEvents(fixtureId);
      return Right(events);
    } catch (_) {
      return const Right([]);
    }
  }

  // ─── Head to Head ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<Fixture>>> getHeadToHead(int homeTeamId, int awayTeamId) async {
    try {
      final fixtures = await remoteDataSource.getHeadToHead(homeTeamId, awayTeamId);
      return Right(fixtures);
    } catch (_) {
      return const Right([]);
    }
  }
}

// ─── Internal TTL Cache Entry ────────────────────────────────────────────────
class _CacheEntry<T> {
  final T data;
  final DateTime expiresAt;

  _CacheEntry(this.data, Duration ttl) : expiresAt = DateTime.now().add(ttl);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
