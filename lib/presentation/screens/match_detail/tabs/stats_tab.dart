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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Teams comparison header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  fixture.homeTeam.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  fixture.statusShort == 'NS' ? 'PRE-MATCH STATS' : 'MATCH STATS',
                  style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  fixture.awayTeam.name,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accent),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Stats list
        Card(
          color: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: statTypes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final type = statTypes[index];
                final values = groupedStats[type]!;
                final homeValue = values[fixture.homeTeam.id] ??
                    (values.values.isNotEmpty ? values.values.first : '-');
                final awayValue = values[fixture.awayTeam.id] ??
                    (values.values.length > 1 ? values.values.elementAt(1) : '-');

                return _buildStatRow(type, homeValue, awayValue);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String title, dynamic homeVal, dynamic awayVal) {
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

    double homePercent = (homeNum / total).clamp(0.05, 0.95);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$homeVal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
            Text('$awayVal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
            const SizedBox(width: 2),
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
