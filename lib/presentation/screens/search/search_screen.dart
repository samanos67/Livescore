import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/fixture_provider.dart';
import '../../widgets/match_card.dart';
import '../team_detail/team_detail_screen.dart';
import '../../../domain/entities/fixture.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const List<Map<String, dynamic>> _popularClubs = [
    {'id': 57, 'name': 'Arsenal', 'logo': 'https://crests.football-data.org/57.png', 'league': 'Premier League'},
    {'id': 65, 'name': 'Manchester City', 'logo': 'https://crests.football-data.org/65.png', 'league': 'Premier League'},
    {'id': 64, 'name': 'Liverpool', 'logo': 'https://crests.football-data.org/64.png', 'league': 'Premier League'},
    {'id': 61, 'name': 'Chelsea', 'logo': 'https://crests.football-data.org/61.png', 'league': 'Premier League'},
    {'id': 66, 'name': 'Manchester United', 'logo': 'https://crests.football-data.org/66.png', 'league': 'Premier League'},
    {'id': 73, 'name': 'Tottenham Hotspur', 'logo': 'https://crests.football-data.org/73.png', 'league': 'Premier League'},
    {'id': 86, 'name': 'Real Madrid', 'logo': 'https://crests.football-data.org/86.png', 'league': 'La Liga'},
    {'id': 81, 'name': 'FC Barcelona', 'logo': 'https://crests.football-data.org/81.png', 'league': 'La Liga'},
    {'id': 78, 'name': 'Atletico Madrid', 'logo': 'https://crests.football-data.org/78.png', 'league': 'La Liga'},
    {'id': 109, 'name': 'Juventus', 'logo': 'https://crests.football-data.org/109.png', 'league': 'Serie A'},
    {'id': 108, 'name': 'Inter Milan', 'logo': 'https://crests.football-data.org/108.png', 'league': 'Serie A'},
    {'id': 98, 'name': 'AC Milan', 'logo': 'https://crests.football-data.org/98.png', 'league': 'Serie A'},
    {'id': 5, 'name': 'Bayern Munich', 'logo': 'https://crests.football-data.org/5.png', 'league': 'Bundesliga'},
    {'id': 4, 'name': 'Borussia Dortmund', 'logo': 'https://crests.football-data.org/4.png', 'league': 'Bundesliga'},
    {'id': 524, 'name': 'Paris Saint-Germain', 'logo': 'https://crests.football-data.org/524.png', 'league': 'Ligue 1'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveMatches = ref.watch(liveFixturesProvider).value ?? [];
    final cleanQuery = _query.trim().toLowerCase();

    // Matching teams
    final matchingClubs = cleanQuery.isEmpty
        ? <Map<String, dynamic>>[]
        : _popularClubs.where((c) {
            final name = c['name'].toString().toLowerCase();
            final league = c['league'].toString().toLowerCase();
            return name.contains(cleanQuery) || league.contains(cleanQuery);
          }).toList();

    // Matching live matches
    final matchingMatches = cleanQuery.isEmpty
        ? <Fixture>[]
        : liveMatches.where((m) {
            final h = m.homeTeam.name.toLowerCase();
            final a = m.awayTeam.name.toLowerCase();
            final l = m.league.name.toLowerCase();
            return h.contains(cleanQuery) || a.contains(cleanQuery) || l.contains(cleanQuery);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: 'Search teams, leagues, matches...',
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 15),
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
          onChanged: (val) => setState(() => _query = val),
        ),
      ),
      body: cleanQuery.isEmpty
          ? _buildDefaultExploreView()
          : _buildSearchResults(matchingClubs, matchingMatches),
    );
  }

  Widget _buildDefaultExploreView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Popular Clubs',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularClubs.take(8).map((club) {
            return ActionChip(
              backgroundColor: AppColors.cardBackground,
              avatar: CachedNetworkImage(
                imageUrl: club['logo'],
                width: 18,
                height: 18,
                errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 16),
              ),
              label: Text(
                club['name'],
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeamDetailScreen(
                      teamId: club['id'],
                      teamName: club['name'],
                      teamLogo: club['logo'],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'All Top European Clubs',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ..._popularClubs.map((club) => _buildClubTile(club)),
      ],
    );
  }

  Widget _buildSearchResults(
    List<Map<String, dynamic>> clubs,
    List<Fixture> matches,
  ) {
    if (clubs.isEmpty && matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No results for "$_query"',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try searching Arsenal, Man City, Real Madrid, etc.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (clubs.isNotEmpty) ...[
          Text(
            'Teams (${clubs.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...clubs.map((c) => _buildClubTile(c)),
          const SizedBox(height: 16),
        ],
        if (matches.isNotEmpty) ...[
          Text(
            'Live Matches (${matches.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...matches.map((m) => MatchCard(fixture: m)),
        ],
      ],
    );
  }

  Widget _buildClubTile(Map<String, dynamic> club) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CachedNetworkImage(
          imageUrl: club['logo'],
          width: 36,
          height: 36,
          fit: BoxFit.contain,
          errorWidget: (_, __, ___) => const Icon(Icons.sports_soccer, size: 30),
        ),
        title: Text(
          club['name'],
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          club['league'],
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeamDetailScreen(
                teamId: club['id'],
                teamName: club['name'],
                teamLogo: club['logo'],
              ),
            ),
          );
        },
      ),
    );
  }
}
