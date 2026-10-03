import 'package:equatable/equatable.dart';

class MatchEvent extends Equatable {
  final int elapsed;
  final int? extra;
  final int teamId;
  final String teamName;
  final String teamLogo;
  final int? playerId;
  final String playerName;
  final int? assistId;
  final String? assistName;
  final String type; // 'Goal', 'Card', 'subst', 'Var'
  final String detail; // 'Normal Goal', 'Yellow Card', 'Red Card', 'Penalty', 'Substitution 1'
  final String? comments;

  const MatchEvent({
    required this.elapsed,
    this.extra,
    required this.teamId,
    required this.teamName,
    required this.teamLogo,
    this.playerId,
    required this.playerName,
    this.assistId,
    this.assistName,
    required this.type,
    required this.detail,
    this.comments,
  });

  bool get isGoal => type.toLowerCase() == 'goal';
  bool get isCard => type.toLowerCase() == 'card';
  bool get isYellowCard => isCard && detail.toLowerCase().contains('yellow');
  bool get isRedCard => isCard && detail.toLowerCase().contains('red');
  bool get isSub => type.toLowerCase() == 'subst' || type.toLowerCase() == 'sub';
  bool get isVar => type.toLowerCase() == 'var';

  @override
  List<Object?> get props => [
        elapsed,
        extra,
        teamId,
        playerId,
        type,
        detail,
      ];
}
