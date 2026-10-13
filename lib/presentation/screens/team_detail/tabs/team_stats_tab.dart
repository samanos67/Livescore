import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../providers/team_provider.dart';

class TeamStatsTab extends ConsumerWidget {
  final int teamId;

  const TeamStatsTab({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(teamStatsProvider(teamId));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Could not load statistics', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(teamStatsProvider(teamId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (stats) {
        if (stats == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No statistics available', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return _StatsBody(stats: stats);
      },
    );
  }
}

class _StatsBody extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    final played   = stats['played'] ?? 0;
    final wins     = stats['wins'] ?? 0;
    final draws    = stats['draws'] ?? 0;
    final losses   = stats['losses'] ?? 0;
    final gf       = stats['goalsFor'] ?? 0;
    final ga       = stats['goalsAgainst'] ?? 0;
    final gd       = stats['goalDifference'] ?? 0;
    final cs       = stats['cleanSheets'] ?? 0;
    final winRate  = stats['winRate'] ?? '0%';
    final avgGF    = stats['avgGoalsScored'] ?? '0.00';
    final avgGA    = stats['avgGoalsConceded'] ?? '0.00';
    final form     = List<String>.from(stats['form'] ?? []);
    final homeRec  = stats['homeRecord'] as Map? ?? {};
    final awayRec  = stats['awayRecord'] as Map? ?? {};
    final upcoming = stats['upcomingCount'] ?? 0;
    final total    = stats['totalFixtures'] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Season Overview Card ───────────────────────────────────────────
        _buildSectionTitle('Season Overview'),
        _buildOverviewGrid(context, played, wins, draws, losses),
        const SizedBox(height: 20),

        // ── Goals Card ────────────────────────────────────────────────────
        _buildSectionTitle('Goals'),
        _buildCard([
          _buildStatRow('Goals Scored', '$gf', valueColor: Colors.green),
          _buildStatRow('Goals Conceded', '$ga', valueColor: Colors.redAccent),
          _buildStatRow('Goal Difference', '${gd >= 0 ? '+' : ''}$gd',
              valueColor: gd >= 0 ? Colors.green : Colors.redAccent),
          _buildStatRow('Clean Sheets', '$cs', valueColor: AppColors.primary),
          _buildStatRow('Avg Goals Scored', avgGF),
          _buildStatRow('Avg Goals Conceded', avgGA),
        ]),
        const SizedBox(height: 20),

        // ── Win Rate & Records ────────────────────────────────────────────
        _buildSectionTitle('Performance'),
        _buildCard([
          _buildStatRow('Win Rate', winRate, valueColor: AppColors.primary),
          _buildStatRow('Home Matches', '${homeRec['played'] ?? 0}'),
          _buildStatRow('Home Wins', '${homeRec['wins'] ?? 0}', valueColor: Colors.green),
          _buildStatRow('Away Matches', '${awayRec['played'] ?? 0}'),
          _buildStatRow('Away Wins', '${awayRec['wins'] ?? 0}', valueColor: Colors.green),
        ]),
        const SizedBox(height: 20),

        // ── Form Guide ────────────────────────────────────────────────────
        if (form.isNotEmpty) ...[
          _buildSectionTitle('Recent Form (Last ${form.length})'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: form.map((r) {
                  final color = r == 'W' ? Colors.green : r == 'D' ? Colors.orange : Colors.red;
                  return Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    child: Center(
                      child: Text(r,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Season Schedule Summary ───────────────────────────────────────
        _buildSectionTitle('Season Schedule'),
        _buildCard([
          _buildStatRow('Total Fixtures This Season', '$total'),
          _buildStatRow('Matches Played', '$played'),
          _buildStatRow('Upcoming Fixtures', '$upcoming', valueColor: AppColors.primary),
        ]),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildOverviewGrid(
      BuildContext context, int played, int wins, int draws, int losses) {
    return Row(
      children: [
        Expanded(child: _StatBox(label: 'Played', value: '$played', color: AppColors.primary)),
        const SizedBox(width: 8),
        Expanded(child: _StatBox(label: 'Won', value: '$wins', color: Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _StatBox(label: 'Drawn', value: '$draws', color: Colors.orange)),
        const SizedBox(width: 8),
        Expanded(child: _StatBox(label: 'Lost', value: '$losses', color: Colors.redAccent)),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
