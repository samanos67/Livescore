import 'package:dio/dio.dart';
import '../../models/standing_model.dart';
import '../../models/team_model.dart';

class TheSportsDbService {
  final Dio dio;

  TheSportsDbService(this.dio);

  static const String baseUrl = 'https://www.thesportsdb.com/api/v1/json/3';

  // Map API-Football league IDs to TheSportsDB league IDs
  static const Map<int, int> leagueIdMap = {
    39: 4328,  // Premier League
    140: 4335, // La Liga
    135: 4332, // Serie A
    78: 4331,  // Bundesliga
    61: 4334,  // Ligue 1
    2: 4480,   // UEFA Champions League
  };

  Future<List<StandingModel>> getLeagueStandings(int apiSportsLeagueId, int season) async {
    final sportsDbLeagueId = leagueIdMap[apiSportsLeagueId];
    if (sportsDbLeagueId == null) return [];

    // TheSportsDB format: 2024-2025
    final seasonStr = '$season-${season + 1}';

    try {
      final response = await dio.get(
        '$baseUrl/lookuptable.php',
        queryParameters: {
          'l': sportsDbLeagueId,
          's': seasonStr,
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final table = response.data['table'];
        if (table is List && table.isNotEmpty) {
          final List<StandingModel> result = [];
          for (var item in table) {
            if (item is Map) {
              final rank = int.tryParse(item['intRank']?.toString() ?? '0') ?? 0;
              final teamName = item['strTeam']?.toString() ?? 'Team';
              final badge = item['strBadge']?.toString() ?? '';
              final played = int.tryParse(item['intPlayed']?.toString() ?? '0') ?? 0;
              final win = int.tryParse(item['intWin']?.toString() ?? '0') ?? 0;
              final draw = int.tryParse(item['intDraw']?.toString() ?? '0') ?? 0;
              final loss = int.tryParse(item['intLoss']?.toString() ?? '0') ?? 0;
              final points = int.tryParse(item['intPoints']?.toString() ?? '0') ?? 0;
              final gd = int.tryParse(item['intGoalDifference']?.toString() ?? '0') ?? 0;
              final goalsFor = int.tryParse(item['intGoalsFor']?.toString() ?? '0') ?? 0;
              final goalsAgainst = int.tryParse(item['intGoalsAgainst']?.toString() ?? '0') ?? 0;
              final form = item['strForm']?.toString() ?? '';
              final teamId = int.tryParse(item['idTeam']?.toString() ?? '0') ?? rank;

              result.add(
                StandingModel(
                  rank: rank,
                  team: TeamModel(
                    id: teamId,
                    name: teamName,
                    logoUrl: badge,
                  ),
                  points: points,
                  goalsDiff: gd,
                  group: 'Regular Season',
                  form: form,
                  status: 'same',
                  description: '',
                  all: StandingStatsModel(
                    played: played,
                    win: win,
                    draw: draw,
                    lose: loss,
                    goalsFor: goalsFor,
                    goalsAgainst: goalsAgainst,
                  ),
                ),
              );
            }
          }
          return result;
        }
      }
    } catch (_) {}

    return [];
  }
}
