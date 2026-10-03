import '../../core/errors/failures.dart';
import '../../domain/entities/fixture.dart';
import '../../domain/repositories/football_repository.dart';
import 'package:dartz/dartz.dart';

class GetFixturesByDate {
  final FootballRepository repository;

  GetFixturesByDate(this.repository);

  Future<Either<Failure, List<Fixture>>> call(String date) async {
    return await repository.getFixturesByDate(DateTime.parse(date));
  }
}
