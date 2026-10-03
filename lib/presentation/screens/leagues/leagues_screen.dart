import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import 'league_detail_screen.dart';

class LeaguesScreen extends StatelessWidget {
  const LeaguesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final leagues = [
      {'id': ApiConstants.premierLeagueId, 'name': 'Premier League (England)', 'country': 'England', 'logo': 'https://media.api-sports.io/football/leagues/39.png'},
      {'id': ApiConstants.laLigaId, 'name': 'La Liga', 'country': 'Spain', 'logo': 'https://media.api-sports.io/football/leagues/140.png'},
      {'id': ApiConstants.serieAId, 'name': 'Serie A', 'country': 'Italy', 'logo': 'https://media.api-sports.io/football/leagues/135.png'},
      {'id': ApiConstants.bundesligaId, 'name': 'Bundesliga', 'country': 'Germany', 'logo': 'https://media.api-sports.io/football/leagues/78.png'},
      {'id': ApiConstants.ligue1Id, 'name': 'Ligue 1', 'country': 'France', 'logo': 'https://media.api-sports.io/football/leagues/61.png'},
      {'id': ApiConstants.championsLeagueId, 'name': 'UEFA Champions League', 'country': 'World', 'logo': 'https://media.api-sports.io/football/leagues/2.png'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Leagues')),
      body: ListView.builder(
        itemCount: leagues.length,
        itemBuilder: (context, index) {
          final league = leagues[index];
          return ListTile(
            leading: Image.network(league['logo'] as String, width: 40),
            title: Text(league['name'] as String),
            subtitle: Text(league['country'] as String),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LeagueDetailScreen(
                    leagueId: league['id'] as int,
                    leagueName: league['name'] as String,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
