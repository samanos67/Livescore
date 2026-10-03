import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/fixture.dart';
import '../repositories/football_repository.dart';

class GetHeadToHead {
  final FootballRepository repository;

  GetHeadToHead(this.repository);

  Future<Either<Failure, List<Fixture>>> call(int homeTeamId, int awayTeamId) async {
    return await repository.getHeadToHead(homeTeamId, awayTeamId);
  }
}
