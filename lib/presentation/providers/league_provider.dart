import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/standing.dart';
import '../../domain/usecases/get_league_standings.dart';
import '../providers/fixture_provider.dart'; // To access repository provider
import '../../core/constants/api_constants.dart';

final getLeagueStandingsProvider = Provider<GetLeagueStandings>((ref) {
  return GetLeagueStandings(ref.read(footballRepositoryProvider));
});

final leagueStandingsProvider = FutureProvider.family<List<Standing>, int>((ref, leagueId) async {
  final getStandings = ref.read(getLeagueStandingsProvider);
  final result = await getStandings(leagueId, ApiConstants.season);
  return result.fold(
    (failure) => throw failure.message,
    (standings) => standings,
  );
});
