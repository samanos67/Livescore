import '../../domain/entities/team.dart';

class TeamModel extends Team {
  const TeamModel({
    required super.id,
    required super.name,
    required super.logoUrl,
    super.winner,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? 'Unknown Team',
      logoUrl: json['logo']?.toString() ?? '',
      winner: json['winner'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logoUrl,
      'winner': winner,
    };
  }
}
