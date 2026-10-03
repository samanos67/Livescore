import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';

class TeamStatsTab extends ConsumerWidget {
  final int teamId;

  const TeamStatsTab({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Top Scorers'),
        ...List.generate(5, (index) => _buildPlayerStatCard(
          name: 'Player ${index + 1}',
          stat: '${15 - index} goals',
        )),
        const SizedBox(height: 24),
        
        _buildSectionTitle('Top Assists'),
        ...List.generate(5, (index) => _buildPlayerStatCard(
          name: 'Player ${index + 6}',
          stat: '${10 - index} assists',
        )),
        const SizedBox(height: 24),
        
        _buildSectionTitle('Team Statistics'),
        _buildTeamStatsCard(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildPlayerStatCard({required String name, required String stat}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(name),
        trailing: Text(
          stat,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTeamStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow('Matches Played', '25'),
            _buildStatRow('Wins', '15'),
            _buildStatRow('Draws', '6'),
            _buildStatRow('Losses', '4'),
            _buildStatRow('Goals Scored', '48'),
            _buildStatRow('Goals Conceded', '22'),
            _buildStatRow('Clean Sheets', '10'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
