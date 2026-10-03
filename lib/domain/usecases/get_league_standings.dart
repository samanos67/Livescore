import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/standing.dart';
import '../repositories/football_repository.dart';

class GetLeagueStandings {
  final FootballRepository repository;

  GetLeagueStandings(this.repository);

  Future<Either<Failure, List<Standing>>> call(int leagueId, int season) async {
    return await repository.getLeagueStandings(leagueId, season);
  }
}
