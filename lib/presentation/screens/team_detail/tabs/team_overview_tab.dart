import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';

class TeamOverviewTab extends ConsumerWidget {
  final int teamId;
  final String teamName;

  const TeamOverviewTab({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Next Fixture'),
        _buildNextFixtureCard(),
        const SizedBox(height: 24),
        
        _buildSectionTitle('Recent Form'),
        _buildRecentFormRow(),
        const SizedBox(height: 24),
        
        _buildSectionTitle('Latest Highlights'),
        _buildHighlightsSection(),
        const SizedBox(height: 24),
        
        _buildSectionTitle('Team News'),
        _buildNewsSection(),
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

  Widget _buildNextFixtureCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Premier League',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text(
              'Saturday, Feb 10 - 15:00',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Icon(Icons.sports_soccer, size: 40),
                    const SizedBox(height: 8),
                    Text(teamName),
                  ],
                ),
                const Text(
                  'VS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Column(
                  children: [
                    Icon(Icons.sports_soccer, size: 40),
                    SizedBox(height: 8),
                    Text('Opponent'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentFormRow() {
    final form = ['W', 'W', 'D', 'L', 'W'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: form.map((result) {
        Color color;
        switch (result) {
          case 'W':
            color = Colors.green;
            break;
          case 'D':
            color = Colors.orange;
            break;
          case 'L':
            color = Colors.red;
            break;
          default:
            color = Colors.grey;
        }
        
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              result,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHighlightsSection() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.play_circle_outline, size: 48, color: AppColors.primary),
            SizedBox(height: 8),
            Text(
              'Latest Match Highlights',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Tap to watch on YouTube',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsSection() {
    return Column(
      children: List.generate(3, (index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.article, color: AppColors.primary),
            title: Text('Team News Article ${index + 1}'),
            subtitle: const Text('2 hours ago'),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      }),
    );
  }
}
