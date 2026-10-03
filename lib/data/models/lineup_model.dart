import '../../domain/entities/lineup.dart';
import 'team_model.dart';

class LineupModel extends Lineup {
  const LineupModel({
    required super.team,
    required super.formation,
    required super.startXI,
    required super.substitutes,
    required super.coach,
  });

  factory LineupModel.fromJson(Map<String, dynamic> json) {
    return LineupModel(
      team: TeamModel.fromJson(json['team']),
      formation: json['formation'] ?? 'Unknown',
      startXI: (json['startXI'] as List).map((e) => PlayerModel.fromJson(e['player'])).toList(),
      substitutes: (json['substitutes'] as List).map((e) => PlayerModel.fromJson(e['player'])).toList(),
      coach: CoachModel.fromJson(json['coach']),
    );
  }
}

class PlayerModel extends Player {
  const PlayerModel({
    required super.id,
    required super.name,
    super.number,
    super.pos,
    super.grid,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'] ?? 0, // Sometimes null in API if unknown
      name: json['name'] ?? 'Unknown',
      number: json['number'],
      pos: json['pos'],
      grid: json['grid'],
    );
  }
}

class CoachModel extends Coach {
  const CoachModel({
    required super.id,
    required super.name,
    super.photo,
  });

  factory CoachModel.fromJson(Map<String, dynamic> json) {
    return CoachModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      photo: json['photo'],
    );
  }
}
