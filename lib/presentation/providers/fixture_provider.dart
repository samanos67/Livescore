import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/fixture.dart';
import '../../domain/usecases/get_live_fixtures.dart';
import '../../domain/usecases/get_fixtures_by_date.dart';
import '../../domain/repositories/football_repository.dart';
import '../../data/repositories/football_repository_impl.dart';
import '../../data/datasources/remote/football_api_service.dart';
import '../../data/datasources/remote/the_sports_db_service.dart';
import 'package:dio/dio.dart';
import '../../services/notification_service.dart';

// ─── Dependency Injection ─────────────────────────────────────────────────────

final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
  ));
});

final footballApiServiceProvider = Provider<FootballApiService>((ref) {
  return FootballApiService(ref.read(dioProvider));
});

final theSportsDbServiceProvider = Provider<TheSportsDbService>((ref) {
  return TheSportsDbService(ref.read(dioProvider));
});

final footballRepositoryProvider = Provider<FootballRepository>((ref) {
  return FootballRepositoryImpl(
    ref.read(footballApiServiceProvider),
    ref.read(theSportsDbServiceProvider),
  );
});

final getLiveFixturesProvider = Provider<GetLiveFixtures>((ref) {
  return GetLiveFixtures(ref.read(footballRepositoryProvider));
});

final getFixturesByDateProvider = Provider<GetFixturesByDate>((ref) {
  return GetFixturesByDate(ref.read(footballRepositoryProvider));
});

// ─── Live Fixtures State (with Auto-Refresh) ─────────────────────────────────

final liveFixturesProvider =
    StateNotifierProvider<FixtureNotifier, AsyncValue<List<Fixture>>>((ref) {
  return FixtureNotifier(ref.read(getLiveFixturesProvider));
});

class FixtureNotifier extends StateNotifier<AsyncValue<List<Fixture>>> {
  final GetLiveFixtures getLiveFixtures;
  Timer? _autoRefreshTimer;
  final Map<int, String> _lastKnownScores = {};

  // Auto-refresh interval: 4 seconds for ultra-fast instant live scores
  static const Duration _refreshInterval = Duration(seconds: 4);

  FixtureNotifier(this.getLiveFixtures) : super(const AsyncValue.loading()) {
    fetchLiveFixtures();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_refreshInterval, (_) {
      fetchLiveFixtures(silent: true);
    });
  }

  /// Fetches live fixtures.
  /// [silent]: if true, keeps the current data visible while refreshing
  ///           (no loading spinner flicker during auto-refresh).
  Future<void> fetchLiveFixtures({bool silent = false}) async {
    if (!silent) {
      state = const AsyncValue.loading();
    }
    final result = await getLiveFixtures();
    result.fold(
      (failure) {
        // On error during silent refresh, keep previous data to avoid flicker
        if (!silent) {
          state = AsyncValue.error(failure.message, StackTrace.current);
        }
      },
      (fixtures) {
        // Detect in-play goal events and trigger instant notifications
        if (_lastKnownScores.isNotEmpty) {
          for (final f in fixtures) {
            final oldScore = _lastKnownScores[f.id];
            final newScore = '${f.goalsHome ?? 0}-${f.goalsAway ?? 0}';
            if (oldScore != null && oldScore != newScore && f.isLive) {
              NotificationService().showGoalAlert(
                matchId: f.id,
                homeTeam: f.homeTeam.name,
                awayTeam: f.awayTeam.name,
                scorerName: 'Live Goal',
                minute: f.elapsed ?? 0,
                homeScore: f.goalsHome ?? 0,
                awayScore: f.goalsAway ?? 0,
              );
            }
          }
        }

        // Cache latest score snapshots
        for (final f in fixtures) {
          _lastKnownScores[f.id] = '${f.goalsHome ?? 0}-${f.goalsAway ?? 0}';
        }

        state = AsyncValue.data(fixtures);
      },
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}

// ─── Fixtures by Date (cached per date string) ────────────────────────────────

final fixturesByDateProvider =
    FutureProvider.family<List<Fixture>, String>((ref, dateString) async {
  final getFixturesByDate = ref.read(getFixturesByDateProvider);
  final result = await getFixturesByDate(dateString);
  return result.fold(
    (failure) => throw failure.message,
    (fixtures) => fixtures,
  );
});
