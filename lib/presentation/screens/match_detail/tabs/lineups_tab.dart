import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/fixture.dart';
import '../../../../domain/entities/lineup.dart';
import '../../../providers/fixture_detail_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../widgets/tactical_pitch_widget.dart';

import '../../../../domain/entities/player.dart' as domain_player;
import '../../../../domain/entities/team.dart';
import '../../../providers/team_provider.dart';

class LineupsTab extends ConsumerWidget {
  final Fixture fixture;

  const LineupsTab({super.key, required this.fixture});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineupsAsync = ref.watch(fixtureLineupsProvider(fixture.id));
    final homeSquadAsync = ref.watch(teamSquadProvider(fixture.homeTeam.id));
    final awaySquadAsync = ref.watch(teamSquadProvider(fixture.awayTeam.id));

    if (lineupsAsync.isLoading && !homeSquadAsync.hasValue && !awaySquadAsync.hasValue) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Determine lineups to display
    List<Lineup> effectiveLineups = [];

    final apiLineups = lineupsAsync.value ?? [];
    if (apiLineups.isNotEmpty) {
      effectiveLineups = apiLineups;
    } else {
      final homeSquad = homeSquadAsync.value ?? [];
      final awaySquad = awaySquadAsync.value ?? [];
      final homeL = _buildProbableLineup(fixture.homeTeam, homeSquad);
      final awayL = _buildProbableLineup(fixture.awayTeam, awaySquad);
      effectiveLineups = [homeL, awayL];
    }

    if (effectiveLineups.isEmpty) {
      final homeL = _buildProbableLineup(fixture.homeTeam, const []);
      final awayL = _buildProbableLineup(fixture.awayTeam, const []);
      effectiveLineups = [homeL, awayL];
    }

    final homeLineup = effectiveLineups.firstWhere(
      (l) => l.team.id == fixture.homeTeam.id,
      orElse: () => effectiveLineups.first,
    );
    final awayLineup = effectiveLineups.firstWhere(
      (l) => l.team.id == fixture.awayTeam.id,
      orElse: () => (effectiveLineups.length > 1 ? effectiveLineups[1] : effectiveLineups.first),
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
              Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fixture.statusShort == 'NS'
                            ? 'Probable Lineup & Squad Roster'
                            : 'Match Lineup & Formation',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        fixture.statusShort == 'NS' ? 'PROBABLE' : 'CONFIRMED',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
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
  }

  Lineup _buildProbableLineup(Team team, List<domain_player.Player> squad) {
    final gks = squad.where((p) => p.position.toLowerCase().contains('goal') || p.position == 'GK').toList();
    final defs = squad.where((p) => p.position.toLowerCase().contains('def') || ['CB', 'LB', 'RB', 'D'].contains(p.position)).toList();
    final mids = squad.where((p) => p.position.toLowerCase().contains('mid') || ['CM', 'CAM', 'DM', 'M'].contains(p.position)).toList();
    final fwds = squad.where((p) => p.position.toLowerCase().contains('forw') || p.position.toLowerCase().contains('strik') || p.position.toLowerCase().contains('offen') || ['LW', 'RW', 'F', 'CF', 'ST'].contains(p.position)).toList();

    final gk = gks.isNotEmpty ? gks.first : (squad.isNotEmpty ? squad.first : null);
    final dList = defs.take(4).toList();
    final mList = mids.take(3).toList();
    final fList = fwds.take(3).toList();

    final usedIds = <int>{
      if (gk != null) gk.id,
      ...dList.map((p) => p.id),
      ...mList.map((p) => p.id),
      ...fList.map((p) => p.id),
    };
    final remaining = squad.where((p) => !usedIds.contains(p.id)).toList();

    while (dList.length < 4 && remaining.isNotEmpty) {
      dList.add(remaining.removeAt(0));
    }
    while (mList.length < 3 && remaining.isNotEmpty) {
      mList.add(remaining.removeAt(0));
    }
    while (fList.length < 3 && remaining.isNotEmpty) {
      fList.add(remaining.removeAt(0));
    }

    const defaultDefs = ['Right Back', 'Centre Back', 'Centre Back', 'Left Back'];
    const defaultMids = ['Central Midfield', 'Defensive Midfield', 'Attacking Midfield'];
    const defaultFwds = ['Right Wing', 'Centre Forward', 'Left Wing'];

    final starters = <Player>[
      Player(
        id: gk?.id ?? (team.id * 100 + 1),
        name: gk?.name ?? 'Goalkeeper',
        number: int.tryParse(gk?.number ?? '1') ?? 1,
        pos: 'G',
        grid: '1:1',
      ),
      for (int i = 0; i < 4; i++)
        Player(
          id: i < dList.length ? dList[i].id : (team.id * 100 + 10 + i),
          name: i < dList.length ? dList[i].name : defaultDefs[i],
          number: i < dList.length ? (int.tryParse(dList[i].number) ?? (i + 2)) : (i + 2),
          pos: 'D',
          grid: '2:${i + 1}',
        ),
      for (int i = 0; i < 3; i++)
        Player(
          id: i < mList.length ? mList[i].id : (team.id * 100 + 20 + i),
          name: i < mList.length ? mList[i].name : defaultMids[i],
          number: i < mList.length ? (int.tryParse(mList[i].number) ?? (i + 6)) : (i + 6),
          pos: 'M',
          grid: '3:${i + 1}',
        ),
      for (int i = 0; i < 3; i++)
        Player(
          id: i < fList.length ? fList[i].id : (team.id * 100 + 30 + i),
          name: i < fList.length ? fList[i].name : defaultFwds[i],
          number: i < fList.length ? (int.tryParse(fList[i].number) ?? (i + 9)) : (i + 9),
          pos: 'F',
          grid: '4:${i + 1}',
        ),
    ];

    final substitutes = remaining.take(9).map((p) =>
      Player(
        id: p.id,
        name: p.name,
        number: int.tryParse(p.number) ?? 12,
        pos: p.position.isNotEmpty ? p.position[0] : 'M',
        grid: null,
      )
    ).toList();

    return Lineup(
      team: team,
      formation: '4-3-3',
      startXI: starters,
      substitutes: substitutes,
      coach: const Coach(id: 0, name: 'Head Coach'),
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
