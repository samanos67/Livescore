import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/favorites_service.dart';

final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  return FavoritesService();
});

// StateNotifier to handle reactive updates
class FavoritesNotifier extends StateNotifier<List<int>> {
  final FavoritesService _service;

  FavoritesNotifier(this._service) : super([]) {
    _loadFavorites();
  }

  void _loadFavorites() {
    state = _service.getFavoriteTeams();
  }

  Future<void> toggleFavorite(int teamId) async {
    await _service.toggleFavoriteTeam(teamId);
    state = _service.getFavoriteTeams(); // Update state
  }

  Future<void> toggle(int teamId) => toggleFavorite(teamId);

  bool isFav(int teamId) => state.contains(teamId);

  Future<void> addMultiple(List<int> teamIds) async {
    await _service.addFavoriteTeams(teamIds);
    state = _service.getFavoriteTeams();
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<int>>((ref) {
  final service = ref.watch(favoritesServiceProvider);
  return FavoritesNotifier(service);
});
