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

  Future<void> addFavoriteTeams(List<int> newTeams) async {
    final teams = getFavoriteTeams();
    for (final id in newTeams) {
      if (!teams.contains(id)) {
        teams.add(id);
      }
    }
    await _saveFavoriteTeams(teams);
  }

  bool hasCompletedOnboarding() {
    return _box.get('has_completed_onboarding', defaultValue: false) as bool;
  }

  Future<void> setCompletedOnboarding([bool completed = true]) async {
    await _box.put('has_completed_onboarding', completed);
  }

  bool areNotificationsEnabled() {
    return _box.get('notifications_enabled', defaultValue: true) as bool;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _box.put('notifications_enabled', enabled);
  }
}
