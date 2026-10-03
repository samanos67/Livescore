import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/fixture.dart';
import '../../../../domain/entities/statistic.dart';
import '../../../providers/fixture_detail_provider.dart';
import '../../../../core/constants/app_colors.dart';

class StatsTab extends ConsumerWidget {
  final Fixture fixture;

  const StatsTab({super.key, required this.fixture});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(fixtureStatisticsProvider(fixture.id));

    return statsAsync.when(
      data: (stats) {
        if (stats.isEmpty) {
          return const Center(child: Text('No statistics available'));
        }
        return _buildStatsList(stats);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildStatsList(List<Statistic> stats) {
    // Group stats by type
    // API returns list where each item is {team, type, value}. 
    // We need to pair them by type to show comparison.
    // e.g. "Shots on Goal" -> Home: 5, Away: 3
    
    final Map<String, Map<int, dynamic>> groupedStats = {};
    
    for (var stat in stats) {
      if (!groupedStats.containsKey(stat.type)) {
        groupedStats[stat.type] = {};
      }
      groupedStats[stat.type]![stat.team.id] = stat.value;
    }

    final statTypes = groupedStats.keys.toList();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: statTypes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final type = statTypes[index];
        final values = groupedStats[type]!;
        final homeValue = values[fixture.homeTeam.id] ?? 0;
        final awayValue = values[fixture.awayTeam.id] ?? 0;
        
        return _buildStatRow(type, homeValue, awayValue);
      },
    );
  }

  Widget _buildStatRow(String title, dynamic homeVal, dynamic awayVal) {
    // Parse values to double for progress bar calculation if possible
    double homeNum = 0;
    double awayNum = 0;
    
    if (homeVal is int) homeNum = homeVal.toDouble();
    if (awayVal is int) awayNum = awayVal.toDouble();
    if (homeVal is String && homeVal.contains('%')) {
        homeNum = double.tryParse(homeVal.replaceAll('%', '')) ?? 0;
    }
    if (awayVal is String && awayVal.contains('%')) {
        awayNum = double.tryParse(awayVal.replaceAll('%', '')) ?? 0;
    }

    double total = homeNum + awayNum;
    if (total == 0) total = 1;
    
    double homePercent = homeNum / total;
    // double awayPercent = awayNum / total; // Not used directly but implied

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$homeVal', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey)),
            Text('$awayVal', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: (homePercent * 100).toInt(),
              child: Container(
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                ),
              ),
            ),
             Expanded(
              flex: ((1 - homePercent) * 100).toInt(),
              child: Container(
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
