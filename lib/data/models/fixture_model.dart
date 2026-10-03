import '../../domain/entities/fixture.dart';
import 'league_model.dart';
import 'team_model.dart';

class FixtureModel extends Fixture {
  const FixtureModel({
    required super.id,
    required super.referee,
    required super.timezone,
    required super.date,
    required super.timestamp,
    required super.statusLong,
    required super.statusShort,
    super.elapsed,
    required super.league,
    required super.homeTeam,
    required super.awayTeam,
    super.goalsHome,
    super.goalsAway,
    super.scoreHalftimeHome,
    super.scoreHalftimeAway,
    super.scoreFulltimeHome,
    super.scoreFulltimeAway,
  });

  factory FixtureModel.fromJson(Map<String, dynamic> json) {
    final fixture = json['fixture'] is Map ? json['fixture'] as Map : {};
    final league = json['league'] is Map ? json['league'] as Map : {};
    final teams = json['teams'] is Map ? json['teams'] as Map : {};
    final goals = json['goals'] is Map ? json['goals'] as Map : {};
    final score = json['score'] is Map ? json['score'] as Map : null;

    DateTime parsedDate;
    try {
      final rawDate = fixture['date']?.toString();
      parsedDate = rawDate != null ? (DateTime.tryParse(rawDate) ?? DateTime.now()) : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final status = fixture['status'] is Map ? fixture['status'] as Map : {};

    return FixtureModel(
      id: fixture['id'] ?? 0,
      referee: fixture['referee']?.toString() ?? 'Unknown',
      timezone: fixture['timezone']?.toString() ?? 'UTC',
      date: parsedDate,
      timestamp: fixture['timestamp'] ?? 0,
      statusLong: status['long']?.toString() ?? 'Not Started',
      statusShort: status['short']?.toString() ?? 'NS',
      elapsed: status['elapsed'] as int?,
      league: LeagueModel.fromJson(Map<String, dynamic>.from(league)),
      homeTeam: TeamModel.fromJson(Map<String, dynamic>.from(teams['home'] is Map ? teams['home'] : {})),
      awayTeam: TeamModel.fromJson(Map<String, dynamic>.from(teams['away'] is Map ? teams['away'] : {})),
      goalsHome: goals['home'] as int?,
      goalsAway: goals['away'] as int?,
      scoreHalftimeHome: score?['halftime']?['home'] as int?,
      scoreHalftimeAway: score?['halftime']?['away'] as int?,
      scoreFulltimeHome: score?['fulltime']?['home'] as int?,
      scoreFulltimeAway: score?['fulltime']?['away'] as int?,
    );
  }
}
