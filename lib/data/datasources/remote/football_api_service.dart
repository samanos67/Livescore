import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/fixture_model.dart';
import '../../models/statistics_model.dart';
import '../../models/lineup_model.dart';
import '../../models/standing_model.dart';
import '../../models/match_event_model.dart';

/// All calls go to our Node.js caching proxy backend.
/// The backend handles multi-provider routing, caching, and keep-alive.
/// To switch environment: change [ApiConstants.backendUrl].
class FootballApiService {
  final Dio dio;

  FootballApiService(this.dio);

  String get _base => ApiConstants.backendUrl;

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Future<dynamic> _get(String path, {Map<String, dynamic>? params}) async {
    try {
      final response = await dio.get(
        '$_base$path',
        queryParameters: params,
        options: Options(receiveTimeout: const Duration(seconds: 20)),
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      throw ServerException();
    } on DioException catch (e) {
      debugPrintException(e);
      throw ServerException();
    } catch (_) {
      throw ServerException();
    }
  }

  void debugPrintException(dynamic e) {
    // ignore: avoid_print
    print('[FootballApiService] Error: $e');
  }

  // ─── Live Fixtures ────────────────────────────────────────────────────────

  Future<List<FixtureModel>> getLiveFixtures() async {
    final data = await _get('/fixtures/live');
    final list = (data['response'] as List?) ?? [];
    final result = <FixtureModel>[];
    for (var item in list) {
      try {
        if (item is Map) result.add(FixtureModel.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {}
    }
    return result;
  }

  // ─── Fixtures by Date ─────────────────────────────────────────────────────

  Future<List<FixtureModel>> getFixturesByDate(String date) async {
    final data = await _get('/fixtures/date/$date');
    final list = (data['response'] as List?) ?? [];
    final result = <FixtureModel>[];
    for (var item in list) {
      try {
        if (item is Map) result.add(FixtureModel.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {}
    }
    return result;
  }

  // ─── Match Statistics ─────────────────────────────────────────────────────

  Future<List<StatisticModel>> getFixtureStatistics(int fixtureId) async {
    final data = await _get('/fixtures/$fixtureId/statistics');
    final list = (data['response'] as List?) ?? [];
    final result = <StatisticModel>[];
    for (var item in list) {
      try {
        if (item is Map) result.add(StatisticModel.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {}
    }
    return result;
  }

  // ─── Lineups ──────────────────────────────────────────────────────────────

  Future<List<LineupModel>> getFixtureLineups(int fixtureId) async {
    final data = await _get('/fixtures/$fixtureId/lineups');
    final list = (data['response'] as List?) ?? [];
    final result = <LineupModel>[];
    for (var item in list) {
      try {
        if (item is Map) result.add(LineupModel.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {}
    }
    return result;
  }

  // ─── Standings ────────────────────────────────────────────────────────────

  Future<List<StandingModel>> getLeagueStandings(int leagueId, int season) async {
    final data = await _get('/standings/$leagueId/$season');
    final list = (data['response'] as List?) ?? [];
    final result = <StandingModel>[];
    for (var item in list) {
      try {
        if (item is Map) result.add(StandingModel.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {}
    }
    return result;
  }

  // ─── Match Events / Timeline ──────────────────────────────────────────────

  Future<List<MatchEventModel>> getFixtureEvents(int fixtureId) async {
    try {
      final data = await _get('/fixtures/$fixtureId/events');
      final list = (data['response'] as List?) ?? [];
      final result = <MatchEventModel>[];
      for (var item in list) {
        try {
          if (item is Map) result.add(MatchEventModel.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {}
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  // ─── Head to Head ─────────────────────────────────────────────────────────

  Future<List<FixtureModel>> getHeadToHead(int homeTeamId, int awayTeamId) async {
    try {
      final data = await _get('/fixtures/h2h/$homeTeamId/$awayTeamId');
      final list = (data['response'] as List?) ?? [];
      final result = <FixtureModel>[];
      for (var item in list) {
        try {
          if (item is Map) result.add(FixtureModel.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {}
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  // ─── Team Info ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getTeamInfo(int teamId) async {
    try {
      final data = await _get('/teams/$teamId');
      final resp = data['response'];
      if (resp is Map) return Map<String, dynamic>.from(resp);
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Team Squad ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTeamSquad(int teamId) async {
    try {
      final data = await _get('/teams/$teamId/squad');
      final list = (data['response'] as List?) ?? [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Team Fixtures ────────────────────────────────────────────────────────

  Future<List<FixtureModel>> getTeamFixtures(int teamId, {String season = '2024'}) async {
    try {
      final data = await _get('/teams/$teamId/fixtures', params: {'season': season});
      final list = (data['response'] as List?) ?? [];
      final result = <FixtureModel>[];
      for (var item in list) {
        try {
          if (item is Map) result.add(FixtureModel.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {}
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  // ─── Team News (RSS aggregator) ───────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTeamNews(String teamName, {int limit = 15}) async {
    try {
      final data = await _get('/news', params: {'team': teamName, 'limit': limit});
      final list = (data['response'] as List?) ?? [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── General News (no team filter) ───────────────────────────────────────

  Future<List<Map<String, dynamic>>> getGeneralNews({int limit = 20}) async {
    try {
      final data = await _get('/news', params: {'limit': limit});
      final list = (data['response'] as List?) ?? [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Team Highlights (YouTube) ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTeamHighlights(String teamName, {int limit = 6}) async {
    try {
      final data = await _get('/highlights', params: {'team': teamName, 'limit': limit});
      final list = (data['response'] as List?) ?? [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Team Season Stats ────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getTeamStats(int teamId, {String season = '2024'}) async {
    try {
      final data = await _get('/teams/$teamId/stats', params: {'season': season});
      final resp = data['response'];
      if (resp is Map) return Map<String, dynamic>.from(resp);
      return null;
    } catch (_) {
      return null;
    }
  }
}

