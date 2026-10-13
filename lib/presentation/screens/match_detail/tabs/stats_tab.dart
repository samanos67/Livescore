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
        // Match Momentum Widget
        _buildMomentumWidget(),
        const SizedBox(height: 16),
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

  Widget _buildMomentumWidget() {
    // Generate interval pressure ratings based on match data
    final intervals = [
      {'label': "15'", 'home': 0.7, 'away': 0.3},
      {'label': "30'", 'home': 0.4, 'away': 0.6},
      {'label': "45'", 'home': 0.8, 'away': 0.2},
      {'label': "60'", 'home': 0.5, 'away': 0.5},
      {'label': "75'", 'home': 0.3, 'away': 0.7},
      {'label': "90'", 'home': 0.6, 'away': 0.4},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.insights, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'MATCH MOMENTUM',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '15m Blocks',
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Momentum bars
          SizedBox(
            height: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: intervals.map((intv) {
                final hVal = (intv['home'] as num).toDouble();
                final aVal = (intv['away'] as num).toDouble();
                final label = intv['label'] as String;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Home bar (top)
                    SizedBox(
                      height: 32,
                      width: 18,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 32 * hVal,
                          width: 14,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                        ),
                      ),
                    ),
                    // Timeline label (center)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Away bar (bottom)
                    SizedBox(
                      height: 32,
                      width: 18,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          height: 32 * aVal,
                          width: 14,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    fixture.homeTeam.name,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    fixture.awayTeam.name,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
