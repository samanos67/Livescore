import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TeamFixturesTab extends ConsumerWidget {
  final int teamId;

  const TeamFixturesTab({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Upcoming Fixtures',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...List.generate(5, (index) => _buildFixtureCard(index, false)),
        const SizedBox(height: 24),
        const Text(
          'Past Results',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...List.generate(5, (index) => _buildFixtureCard(index, true)),
      ],
    );
  }

  Widget _buildFixtureCard(int index, bool isPast) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Premier League',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPast ? 'Feb ${7 - index}' : 'Feb ${10 + index}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (isPast)
              Text(
                '${2 + index} - ${1 + index}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            else
              const Text(
                '15:00',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(width: 16),
            const Text('vs Opponent'),
          ],
        ),
      ),
    );
  }
}
