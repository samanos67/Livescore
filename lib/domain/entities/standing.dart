import 'package:equatable/equatable.dart';
import 'team.dart';

class Standing extends Equatable {
  final int rank;
  final Team team;
  final int points;
  final int goalsDiff;
  final String group;
  final String form;
  final String status;
  final String description;
  final StandingStats all;

  const Standing({
    required this.rank,
    required this.team,
    required this.points,
    required this.goalsDiff,
    required this.group,
    required this.form,
    required this.status,
    required this.description,
    required this.all,
  });

  @override
  List<Object?> get props => [rank, team, points, goalsDiff, group, form, status, description, all];
}

class StandingStats extends Equatable {
  final int played;
  final int win;
  final int draw;
  final int lose;
  final int goalsFor;
  final int goalsAgainst;

  const StandingStats({
    required this.played,
    required this.win,
    required this.draw,
    required this.lose,
    required this.goalsFor,
    required this.goalsAgainst,
  });

  @override
  List<Object?> get props => [played, win, draw, lose, goalsFor, goalsAgainst];
}
