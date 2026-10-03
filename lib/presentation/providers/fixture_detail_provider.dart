import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/statistic.dart';
import '../../domain/entities/lineup.dart';
import '../../domain/entities/match_event.dart';
import '../../domain/entities/fixture.dart';
import '../../domain/usecases/get_fixture_statistics.dart';
import '../../domain/usecases/get_fixture_lineups.dart';
import '../../domain/usecases/get_fixture_events.dart';
import '../../domain/usecases/get_head_to_head.dart';
import 'fixture_provider.dart';

final getFixtureStatisticsProvider = Provider<GetFixtureStatistics>((ref) {
  return GetFixtureStatistics(ref.read(footballRepositoryProvider));
});

final getFixtureLineupsProvider = Provider<GetFixtureLineups>((ref) {
  return GetFixtureLineups(ref.read(footballRepositoryProvider));
});

final getFixtureEventsUsecaseProvider = Provider<GetFixtureEvents>((ref) {
  return GetFixtureEvents(ref.read(footballRepositoryProvider));
});

final getHeadToHeadUsecaseProvider = Provider<GetHeadToHead>((ref) {
  return GetHeadToHead(ref.read(footballRepositoryProvider));
});

final fixtureStatisticsProvider = FutureProvider.family<List<Statistic>, int>((ref, fixtureId) async {
  final getStats = ref.read(getFixtureStatisticsProvider);
  final result = await getStats(fixtureId);
  return result.fold(
    (failure) => throw failure.message,
    (stats) => stats,
  );
});

final fixtureLineupsProvider = FutureProvider.family<List<Lineup>, int>((ref, fixtureId) async {
  final getLineups = ref.read(getFixtureLineupsProvider);
  final result = await getLineups(fixtureId);
  return result.fold(
    (failure) => throw failure.message,
    (lineups) => lineups,
  );
});

final fixtureEventsProvider = FutureProvider.family<List<MatchEvent>, int>((ref, fixtureId) async {
  final getEvents = ref.read(getFixtureEventsUsecaseProvider);
  final result = await getEvents(fixtureId);
  return result.fold(
    (failure) => throw failure.message,
    (events) => events,
  );
});

// Keyed by "homeId-awayId"
final headToHeadProvider = FutureProvider.family<List<Fixture>, String>((ref, h2hKey) async {
  final parts = h2hKey.split('-');
  if (parts.length != 2) return [];
  final homeId = int.tryParse(parts[0]) ?? 0;
  final awayId = int.tryParse(parts[1]) ?? 0;
  final getH2H = ref.read(getHeadToHeadUsecaseProvider);
  final result = await getH2H(homeId, awayId);
  return result.fold(
    (failure) => throw failure.message,
    (fixtures) => fixtures,
  );
});
