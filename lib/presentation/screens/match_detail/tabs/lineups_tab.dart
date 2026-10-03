import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/fixture.dart';
import '../../../../domain/entities/lineup.dart';
import '../../../providers/fixture_detail_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../widgets/tactical_pitch_widget.dart';

class LineupsTab extends ConsumerWidget {
  final Fixture fixture;

  const LineupsTab({super.key, required this.fixture});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineupsAsync = ref.watch(fixtureLineupsProvider(fixture.id));

    return lineupsAsync.when(
      data: (lineups) {
        if (lineups.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 56, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Lineups Not Announced Yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Confirmed lineups are usually released 45-60 minutes before kick-off.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final homeLineup = lineups.firstWhere(
          (l) => l.team.id == fixture.homeTeam.id,
          orElse: () => lineups[0],
        );
        final awayLineup = lineups.firstWhere(
          (l) => l.team.id == fixture.awayTeam.id,
          orElse: () => (lineups.length > 1 ? lineups[1] : lineups[0]),
        );

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                color: AppColors.secondary,
                child: TabBar(
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: fixture.homeTeam.name),
                    Tab(text: fixture.awayTeam.name),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildLineupView(homeLineup, isHome: true),
                    _buildLineupView(awayLineup, isHome: false),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Could not load lineups: $err'),
        ),
      ),
    );
  }

  Widget _buildLineupView(Lineup lineup, {required bool isHome}) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Tactical Pitch Formation
        TacticalPitchWidget(lineup: lineup, isHome: isHome),

        // Starting XI List
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: isHome ? AppColors.primary : Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'STARTING XI',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              Text(
                'Formation ${lineup.formation}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lineup.startXI.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
            itemBuilder: (context, index) {
              final player = lineup.startXI[index];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: isHome
                      ? AppColors.primary.withOpacity(0.2)
                      : Colors.orangeAccent.withOpacity(0.2),
                  child: Text(
                    player.number != null ? '${player.number}' : '-',
                    style: TextStyle(
                      color: isHome ? AppColors.primary : Colors.orangeAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  player.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    player.pos ?? '',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
        ),

        // Substitutes Bench
        if (lineup.substitutes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'SUBSTITUTES',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: AppColors.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lineup.substitutes.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
              itemBuilder: (context, index) {
                final player = lineup.substitutes[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white10,
                    child: Text(
                      player.number != null ? '${player.number}' : '-',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    player.name,
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      player.pos ?? '',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        // Coach
        if (lineup.coach.name.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'MANAGER',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: AppColors.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
              title: Text(
                lineup.coach.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: const Text(
                'Head Coach',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
