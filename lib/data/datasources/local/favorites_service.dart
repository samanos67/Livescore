import 'package:hive_flutter/hive_flutter.dart';

class FavoritesService {
  static const String boxName = 'favorites';
  
  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
  }

  Box get _box => Hive.box(boxName);

  List<int> getFavoriteTeams() {
    // Storing as List<int>
    return _box.get('teams', defaultValue: <int>[])!.cast<int>();
  }

  Future<void> _saveFavoriteTeams(List<int> teams) async {
    await _box.put('teams', teams);
  }

  Future<void> toggleFavoriteTeam(int teamId) async {
    final teams = getFavoriteTeams();
    if (teams.contains(teamId)) {
      teams.remove(teamId);
    } else {
      teams.add(teamId);
    }
    await _saveFavoriteTeams(teams);
  }

  bool isFavoriteTeam(int teamId) {
    final teams = getFavoriteTeams();
    return teams.contains(teamId);
  }
}
