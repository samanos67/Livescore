import 'package:equatable/equatable.dart';
import 'league.dart';
import 'team.dart';

class Fixture extends Equatable {
  final int id;
  final String referee;
  final String timezone;
  final DateTime date;
  final int timestamp;
  
  final String statusLong;  // "Match Finished"
  final String statusShort; // "FT", "1H", "NS"
  final int? elapsed;
  
  final League league;
  final Team homeTeam;
  final Team awayTeam;
  
  final int? goalsHome;
  final int? goalsAway;
  final int? scoreHalftimeHome;
  final int? scoreHalftimeAway;
  final int? scoreFulltimeHome;
  final int? scoreFulltimeAway;

  const Fixture({
    required this.id,
    required this.referee,
    required this.timezone,
    required this.date,
    required this.timestamp,
    required this.statusLong,
    required this.statusShort,
    this.elapsed,
    required this.league,
    required this.homeTeam,
    required this.awayTeam,
    this.goalsHome,
    this.goalsAway,
    this.scoreHalftimeHome,
    this.scoreHalftimeAway,
    this.scoreFulltimeHome,
    this.scoreFulltimeAway,
  });

  bool get isLive {
    return ['1H', 'HT', '2H', 'ET', 'BT', 'P', 'SUSP', 'INT'].contains(statusShort);
  }
  
  bool get isFinished {
    return ['FT', 'AET', 'PEN'].contains(statusShort);
  }

  @override
  List<Object?> get props => [
    id, referee, timezone, date, timestamp, statusLong, statusShort, elapsed,
    league, homeTeam, awayTeam, goalsHome, goalsAway
  ];
}
