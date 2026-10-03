import 'package:equatable/equatable.dart';
import 'team.dart';

class Lineup extends Equatable {
  final Team team;
  final String formation;
  final List<Player> startXI;
  final List<Player> substitutes;
  final Coach coach;

  const Lineup({
    required this.team,
    required this.formation,
    required this.startXI,
    required this.substitutes,
    required this.coach,
  });

  @override
  List<Object?> get props => [team, formation, startXI, substitutes, coach];
}

class Player extends Equatable {
  final int id;
  final String name;
  final int? number;
  final String? pos;
  final String? grid;

  const Player({
    required this.id,
    required this.name,
    this.number,
    this.pos,
    this.grid,
  });

  @override
  List<Object?> get props => [id, name, number, pos, grid];
}

class Coach extends Equatable {
  final int id;
  final String name;
  final String? photo;

  const Coach({
    required this.id,
    required this.name,
    this.photo,
  });

  @override
  List<Object?> get props => [id, name, photo];
}
