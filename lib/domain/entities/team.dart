import 'package:equatable/equatable.dart';

class Team extends Equatable {
  final int id;
  final String name;
  final String logoUrl;
  final bool? winner;

  const Team({
    required this.id,
    required this.name,
    required this.logoUrl,
    this.winner,
  });

  @override
  List<Object?> get props => [id, name, logoUrl, winner];
}
