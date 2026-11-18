import 'package:equatable/equatable.dart';

class MatchPrediction extends Equatable {
  final int fixtureId;
  final String homeTeam;
  final String awayTeam;
  final int predictedHomeScore;
  final int predictedAwayScore;
  final int homeWinProb;
  final int drawProb;
  final int awayWinProb;
  final double homeXg;
  final double awayXg;
  final int confidence;
  final List<String> keyFactors;
  final String tacticalInsight;
  final bool btts;
  final bool over25Goals;
  final String model;
  final String disclaimer;
  final DateTime generatedAt;

  const MatchPrediction({
    required this.fixtureId,
    required this.homeTeam,
    required this.awayTeam,
    required this.predictedHomeScore,
    required this.predictedAwayScore,
    required this.homeWinProb,
    required this.drawProb,
    required this.awayWinProb,
    required this.homeXg,
    required this.awayXg,
    required this.confidence,
    required this.keyFactors,
    required this.tacticalInsight,
    required this.btts,
    required this.over25Goals,
    required this.model,
    required this.disclaimer,
    required this.generatedAt,
  });

  String get predictedScoreString => '$predictedHomeScore - $predictedAwayScore';

  String get favoriteOutcome {
    if (homeWinProb > awayWinProb && homeWinProb > drawProb) {
      return '$homeTeam Win ($homeWinProb%)';
    } else if (awayWinProb > homeWinProb && awayWinProb > drawProb) {
      return '$awayTeam Win ($awayWinProb%)';
    } else {
      return 'Draw ($drawProb%)';
    }
  }

  @override
  List<Object?> get props => [
        fixtureId,
        homeTeam,
        awayTeam,
        predictedHomeScore,
        predictedAwayScore,
        homeWinProb,
        drawProb,
        awayWinProb,
        homeXg,
        awayXg,
        confidence,
        keyFactors,
        tacticalInsight,
        btts,
        over25Goals,
        model,
        disclaimer,
        generatedAt,
      ];
}
