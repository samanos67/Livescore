import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/fixture.dart';
import '../repositories/football_repository.dart';

class GetLiveFixtures {
  final FootballRepository repository;

  GetLiveFixtures(this.repository);

  Future<Either<Failure, List<Fixture>>> call() async {
    return await repository.getLiveFixtures();
  }
}
