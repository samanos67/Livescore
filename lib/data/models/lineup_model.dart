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
    final teamMap = json['team'] is Map ? Map<String, dynamic>.from(json['team'] as Map) : <String, dynamic>{};
    final coachMap = json['coach'] is Map ? Map<String, dynamic>.from(json['coach'] as Map) : <String, dynamic>{};
    final startList = json['startXI'] is List ? json['startXI'] as List : [];
    final subList = json['substitutes'] is List ? json['substitutes'] as List : [];

    return LineupModel(
      team: TeamModel.fromJson(teamMap),
      formation: json['formation']?.toString() ?? '4-3-3',
      startXI: startList.map((e) {
        if (e is Map) {
          final pMap = e['player'] is Map ? Map<String, dynamic>.from(e['player'] as Map) : Map<String, dynamic>.from(e);
          return PlayerModel.fromJson(pMap);
        }
        return const PlayerModel(id: 0, name: 'Player');
      }).toList(),
      substitutes: subList.map((e) {
        if (e is Map) {
          final pMap = e['player'] is Map ? Map<String, dynamic>.from(e['player'] as Map) : Map<String, dynamic>.from(e);
          return PlayerModel.fromJson(pMap);
        }
        return const PlayerModel(id: 0, name: 'Substitute');
      }).toList(),
      coach: CoachModel.fromJson(coachMap),
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
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Player',
      number: (json['number'] as num?)?.toInt(),
      pos: json['pos']?.toString(),
      grid: json['grid']?.toString(),
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
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Coach',
      photo: json['photo']?.toString(),
    );
  }
}
