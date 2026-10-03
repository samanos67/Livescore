import '../../domain/entities/statistic.dart';
import 'team_model.dart';

class StatisticModel extends Statistic {
  const StatisticModel({
    required super.team,
    required super.type,
    required super.value,
  });

  factory StatisticModel.fromJson(Map<String, dynamic> json) {
    return StatisticModel(
      team: TeamModel.fromJson(json['team']),
      type: json['type'],
      value: json['value'],
    );
  }
}
