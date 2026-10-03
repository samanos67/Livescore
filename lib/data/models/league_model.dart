import '../../domain/entities/league.dart';

class LeagueModel extends League {
  const LeagueModel({
    required super.id,
    required super.name,
    required super.country,
    required super.logoUrl,
    super.flagUrl,
    super.season,
    super.round,
  });

  factory LeagueModel.fromJson(Map<String, dynamic> json) {
    return LeagueModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? 'Unknown League',
      country: json['country']?.toString() ?? '',
      logoUrl: json['logo']?.toString() ?? '',
      flagUrl: json['flag']?.toString(),
      season: json['season'] as int?,
      round: json['round']?.toString(),
    );
  }
}
