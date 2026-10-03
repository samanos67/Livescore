import '../../domain/entities/standing.dart';
import 'team_model.dart';

class StandingModel extends Standing {
  const StandingModel({
    required super.rank,
    required super.team,
    required super.points,
    required super.goalsDiff,
    required super.group,
    required super.form,
    required super.status,
    required super.description,
    required super.all,
  });

  factory StandingModel.fromJson(Map<String, dynamic> json) {
    return StandingModel(
      rank: json['rank'],
      team: TeamModel.fromJson(json['team']),
      points: json['points'],
      goalsDiff: json['goalsDiff'],
      group: json['group'],
      form: json['form'] ?? '',
      status: json['status'],
      description: json['description'] ?? '',
      all: StandingStatsModel.fromJson(json['all']),
    );
  }
}

class StandingStatsModel extends StandingStats {
  const StandingStatsModel({
    required super.played,
    required super.win,
    required super.draw,
    required super.lose,
    required super.goalsFor,
    required super.goalsAgainst,
  });

  factory StandingStatsModel.fromJson(Map<String, dynamic> json) {
    return StandingStatsModel(
      played: json['played'],
      win: json['win'],
      draw: json['draw'],
      lose: json['lose'],
      goalsFor: json['goals']['for'],
      goalsAgainst: json['goals']['against'],
    );
  }
}
