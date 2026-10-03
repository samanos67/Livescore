import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/fixture.dart';
import '../../../providers/fixture_detail_provider.dart';

class H2HTab extends ConsumerWidget {
  final Fixture fixture;

  const H2HTab({super.key, required this.fixture});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h2hKey = '${fixture.homeTeam.id}-${fixture.awayTeam.id}';
    final h2hAsync = ref.watch(headToHeadProvider(h2hKey));

    return h2hAsync.when(
      data: (fixtures) {
        if (fixtures.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 56, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No Head-to-Head History',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'These two clubs have no recorded previous encounters.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        int homeWins = 0;
        int awayWins = 0;
        int draws = 0;

        for (var f in fixtures) {
          final gHome = f.goalsHome ?? 0;
          final gAway = f.goalsAway ?? 0;
          if (f.homeTeam.id == fixture.homeTeam.id) {
            if (gHome > gAway) {
              homeWins++;
            } else if (gAway > gHome) {
              awayWins++;
            } else {
              draws++;
            }
          } else {
            if (gAway > gHome) {
              homeWins++;
            } else if (gHome > gAway) {
              awayWins++;
            } else {
              draws++;
            }
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildH2HSummary(fixtures.length, homeWins, draws, awayWins),
            const SizedBox(height: 20),
            _buildSectionHeader('PREVIOUS MEETINGS (${fixtures.length})'),
            const SizedBox(height: 12),
            ...fixtures.map((f) => _buildMeetingCard(f)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Could not load H2H: $err')),
    );
  }

  Widget _buildH2HSummary(int total, int homeWins, int draws, int awayWins) {
    final homePercent = total > 0 ? (homeWins / total) : 0.0;
    final drawPercent = total > 0 ? (draws / total) : 0.0;
    final awayPercent = total > 0 ? (awayWins / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Text(
            'HEAD TO HEAD SUMMARY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCol(fixture.homeTeam.name, '$homeWins', AppColors.primary),
              _buildStatCol('Draws', '$draws', Colors.grey),
              _buildStatCol(fixture.awayTeam.name, '$awayWins', Colors.orangeAccent),
            ],
          ),
          const SizedBox(height: 14),
          // Stacked distribution bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: (homePercent * 100).toInt(),
                    child: Container(color: AppColors.primary),
                  ),
                  Expanded(
                    flex: (drawPercent * 100).toInt(),
                    child: Container(color: Colors.grey),
                  ),
                  Expanded(
                    flex: (awayPercent * 100).toInt(),
                    child: Container(color: Colors.orangeAccent),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(maxWidth: 90),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingCard(Fixture match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                match.league.name,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              Text(
                DateFormat('d MMM yyyy').format(match.date),
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Home team
              Expanded(
                child: Row(
                  children: [
                    if (match.homeTeam.logoUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: match.homeTeam.logoUrl,
                        width: 20,
                        height: 20,
                        errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 20),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        match.homeTeam.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              // Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${match.goalsHome ?? 0} - ${match.goalsAway ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              // Away team
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        match.awayTeam.name,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (match.awayTeam.logoUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: match.awayTeam.logoUrl,
                        width: 20,
                        height: 20,
                        errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 20),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
