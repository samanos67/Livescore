import '../../domain/entities/match_prediction.dart';

class MatchPredictionModel extends MatchPrediction {
  const MatchPredictionModel({
    required super.fixtureId,
    required super.homeTeam,
    required super.awayTeam,
    required super.predictedHomeScore,
    required super.predictedAwayScore,
    required super.homeWinProb,
    required super.drawProb,
    required super.awayWinProb,
    required super.homeXg,
    required super.awayXg,
    required super.confidence,
    required super.keyFactors,
    required super.tacticalInsight,
    required super.btts,
    required super.over25Goals,
    required super.model,
    required super.disclaimer,
    required super.generatedAt,
  });

  factory MatchPredictionModel.fromJson(Map<String, dynamic> json) {
    final predScore = json['predictedScore'] as Map<String, dynamic>? ?? {};
    final probs = json['probabilities'] as Map<String, dynamic>? ?? {};
    final xg = json['xG'] as Map<String, dynamic>? ?? {};

    return MatchPredictionModel(
      fixtureId: (json['fixtureId'] as num?)?.toInt() ?? 0,
      homeTeam: json['homeTeam'] as String? ?? 'Home Team',
      awayTeam: json['awayTeam'] as String? ?? 'Away Team',
      predictedHomeScore: (predScore['home'] as num?)?.toInt() ?? 1,
      predictedAwayScore: (predScore['away'] as num?)?.toInt() ?? 1,
      homeWinProb: (probs['homeWin'] as num?)?.toInt() ?? 45,
      drawProb: (probs['draw'] as num?)?.toInt() ?? 25,
      awayWinProb: (probs['awayWin'] as num?)?.toInt() ?? 30,
      homeXg: (xg['home'] as num?)?.toDouble() ?? 1.45,
      awayXg: (xg['away'] as num?)?.toDouble() ?? 1.15,
      confidence: (json['confidence'] as num?)?.toInt() ?? 75,
      keyFactors: (json['keyFactors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      tacticalInsight: json['tacticalInsight'] as String? ?? '',
      btts: json['btts'] as bool? ?? false,
      over25Goals: json['over25Goals'] as bool? ?? false,
      model: json['model'] as String? ?? 'gemini-2.0-flash',
      disclaimer: json['disclaimer'] as String? ??
          'Predictions are AI-generated statistical estimates for entertainment purposes only.',
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fixtureId': fixtureId,
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'predictedScore': {
        'home': predictedHomeScore,
        'away': predictedAwayScore,
      },
      'probabilities': {
        'homeWin': homeWinProb,
        'draw': drawProb,
        'awayWin': awayWinProb,
      },
      'xG': {
        'home': homeXg,
        'away': awayXg,
      },
      'confidence': confidence,
      'keyFactors': keyFactors,
      'tacticalInsight': tacticalInsight,
      'btts': btts,
      'over25Goals': over25Goals,
      'model': model,
      'disclaimer': disclaimer,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}
