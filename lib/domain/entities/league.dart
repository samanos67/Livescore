import 'package:equatable/equatable.dart';

class League extends Equatable {
  final int id;
  final String name;
  final String country;
  final String logoUrl;
  final String? flagUrl;
  final int? season;
  final String? round;

  const League({
    required this.id,
    required this.name,
    required this.country,
    required this.logoUrl,
    this.flagUrl,
    this.season,
    this.round,
  });

  @override
  List<Object?> get props => [id, name, country, logoUrl, flagUrl, season, round];
}
