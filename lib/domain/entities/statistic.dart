import 'package:equatable/equatable.dart';
import 'team.dart';

class Statistic extends Equatable {
  final Team team;
  final String type;
  final dynamic value; // Can be int (5) or String ("50%")

  const Statistic({
    required this.team,
    required this.type,
    required this.value,
  });

  @override
  List<Object?> get props => [team, type, value];
}
