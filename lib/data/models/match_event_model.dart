import '../../domain/entities/match_event.dart';

class MatchEventModel extends MatchEvent {
  const MatchEventModel({
    required super.elapsed,
    super.extra,
    required super.teamId,
    required super.teamName,
    required super.teamLogo,
    super.playerId,
    required super.playerName,
    super.assistId,
    super.assistName,
    required super.type,
    required super.detail,
    super.comments,
  });

  factory MatchEventModel.fromJson(Map<String, dynamic> json) {
    final time = json['time'] is Map ? json['time'] as Map : {};
    final team = json['team'] is Map ? json['team'] as Map : {};
    final player = json['player'] is Map ? json['player'] as Map : {};
    final assist = json['assist'] is Map ? json['assist'] as Map : {};

    return MatchEventModel(
      elapsed: (time['elapsed'] as num?)?.toInt() ?? 0,
      extra: (time['extra'] as num?)?.toInt(),
      teamId: (team['id'] as num?)?.toInt() ?? 0,
      teamName: team['name']?.toString() ?? 'Team',
      teamLogo: team['logo']?.toString() ?? '',
      playerId: (player['id'] as num?)?.toInt(),
      playerName: player['name']?.toString() ?? 'Unknown Player',
      assistId: (assist['id'] as num?)?.toInt(),
      assistName: assist['name']?.toString(),
      type: json['type']?.toString() ?? 'Event',
      detail: json['detail']?.toString() ?? '',
      comments: json['comments']?.toString(),
    );
  }
}
