import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/league_provider.dart';
import '../../widgets/standings_table.dart';
import '../../widgets/banner_ad_widget.dart';

class LeagueDetailScreen extends ConsumerWidget {
  final int leagueId;
  final String leagueName;

  const LeagueDetailScreen({
    super.key,
    required this.leagueId,
    required this.leagueName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(leagueStandingsProvider(leagueId));

    return Scaffold(
      appBar: AppBar(
        title: Text(leagueName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(leagueStandingsProvider(leagueId));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const BannerAdWidget(),
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[900],
            child: Row(
              children: [
                const SizedBox(width: 30, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                const SizedBox(width: 36), // Space for logo
                const Expanded(child: Text('Team', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                _buildHeaderStat('P', 40),
                _buildHeaderStat('W', 30),
                _buildHeaderStat('D', 30),
                _buildHeaderStat('L', 30),
                _buildHeaderStat('GD', 40),
                _buildHeaderStat('Pts', 40),
              ],
            ),
          ),
          Expanded(
            child: standingsAsync.when(
              data: (standings) {
                if (standings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.table_chart, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No standings available',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(leagueStandingsProvider(leagueId));
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                final sortedStandings = List.of(standings)
                  ..sort((a, b) => a.rank.compareTo(b.rank));
                
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(leagueStandingsProvider(leagueId));
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        StandingsTable(standings: sortedStandings),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $err'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(leagueStandingsProvider(leagueId));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, double width) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
