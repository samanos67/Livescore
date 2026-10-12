import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../providers/team_provider.dart';
import '../../../../domain/entities/fixture.dart';

class TeamFixturesTab extends ConsumerWidget {
  final int teamId;

  const TeamFixturesTab({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fixturesAsync = ref.watch(teamFixturesProvider(teamId));

    return fixturesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Could not load fixtures', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(teamFixturesProvider(teamId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (fixtures) {
        if (fixtures.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No fixtures available', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final now      = DateTime.now();
        final upcoming = fixtures.where((f) =>
          (f.fixture.status.short == 'NS' || f.fixture.status.short == 'TBD') &&
          f.fixture.date.isAfter(now)
        ).toList()..sort((a, b) => a.fixture.date.compareTo(b.fixture.date));

        final past = fixtures.where((f) =>
          f.fixture.status.short == 'FT' ||
          f.fixture.status.short == 'AET' ||
          f.fixture.status.short == 'PEN'
        ).toList()..sort((a, b) => b.fixture.date.compareTo(a.fixture.date));

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (upcoming.isNotEmpty) ...[
              _SectionHeader('Upcoming Fixtures (${upcoming.length})'),
              ...upcoming.take(10).map((f) => _FixtureRow(fixture: f, teamId: teamId)),
              const SizedBox(height: 12),
            ],
            if (past.isNotEmpty) ...[
              _SectionHeader('Results (${past.length})'),
              ...past.take(15).map((f) => _FixtureRow(fixture: f, teamId: teamId)),
            ],
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }
}

class _FixtureRow extends StatelessWidget {
  final Fixture fixture;
  final int teamId;
  const _FixtureRow({required this.fixture, required this.teamId});

  @override
  Widget build(BuildContext context) {
    final f         = fixture.fixture;
    final home      = fixture.teams.home;
    final away      = fixture.teams.away;
    final isLive    = fixture.isLive;
    final isFinished = f.status.short == 'FT' || f.status.short == 'AET';
    final homeGoals = fixture.goals.home;
    final awayGoals = fixture.goals.away;

    final dateStr = DateFormat('EEE d MMM').format(f.date.toLocal());
    final timeStr = DateFormat('HH:mm').format(f.date.toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(fixture.league.name, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const Spacer(),
                Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Home team
                Expanded(
                  child: Row(
                    children: [
                      _TeamBadge(logo: home.logo),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          home.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: home.id == teamId ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Score or Time
                Container(
                  width: 80,
                  alignment: Alignment.center,
                  child: isFinished
                      ? Text(
                          '$homeGoals - $awayGoals',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        )
                      : isLive
                          ? Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    f.status.short,
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$homeGoals - $awayGoals',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          : Text(
                              timeStr,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                ),
                // Away team
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          away.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontWeight: away.id == teamId ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _TeamBadge(logo: away.logo),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamBadge extends StatelessWidget {
  final String logo;
  const _TeamBadge({required this.logo});

  @override
  Widget build(BuildContext context) {
    if (logo.isEmpty) return const Icon(Icons.sports_soccer, size: 24, color: Colors.grey);
    return CachedNetworkImage(
      imageUrl: logo,
      width: 24,
      height: 24,
      errorWidget: (_, __, ___) => const Icon(Icons.sports_soccer, size: 24, color: Colors.grey),
    );
  }
}
