import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/fixture.dart';
import '../../../../domain/entities/match_event.dart';
import '../../../providers/fixture_detail_provider.dart';

class OverviewTab extends ConsumerWidget {
  final Fixture fixture;

  const OverviewTab({super.key, required this.fixture});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(fixtureEventsProvider(fixture.id));

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildMatchHeaderCard(context),
        const SizedBox(height: 20),
        _buildSectionTitle('MATCH TIMELINE'),
        const SizedBox(height: 12),
        eventsAsync.when(
          data: (events) => _buildTimelineSection(events),
          loading: () => const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => _buildEmptyTimeline('No events available yet'),
        ),
      ],
    );
  }

  Widget _buildMatchHeaderCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // League info row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (fixture.league.logoUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: fixture.league.logoUrl,
                  width: 18,
                  height: 18,
                  errorWidget: (_, __, ___) => const Icon(Icons.sports_soccer, size: 18),
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  fixture.league.name,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Teams and Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _buildTeamCol(fixture.homeTeam.name, fixture.homeTeam.logoUrl)),
              _buildScoreDisplay(),
              Expanded(child: _buildTeamCol(fixture.awayTeam.name, fixture.awayTeam.logoUrl)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          // Info row: Date, Venue, Referee
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                Icons.calendar_today,
                DateFormat('EEE, d MMM yyyy • HH:mm').format(fixture.date),
              ),
              if (fixture.referee != 'Unknown' && fixture.referee.isNotEmpty)
                _buildInfoChip(Icons.sports, fixture.referee),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCol(String name, String logoUrl) {
    return Column(
      children: [
        CachedNetworkImage(
          imageUrl: logoUrl,
          width: 52,
          height: 52,
          placeholder: (_, __) => const CircleAvatar(backgroundColor: Colors.white10, radius: 26),
          errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 52, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreDisplay() {
    if (fixture.statusShort == 'NS') {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              DateFormat('HH:mm').format(fixture.date),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kick Off',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${fixture.goalsHome ?? 0} - ${fixture.goalsAway ?? 0}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: fixture.isLive ? Colors.redAccent.withOpacity(0.2) : Colors.white10,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            fixture.isLive ? "${fixture.elapsed}' LIVE" : fixture.statusLong,
            style: TextStyle(
              color: fixture.isLive ? Colors.redAccent : Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
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

  Widget _buildTimelineSection(List<MatchEvent> events) {
    if (events.isEmpty) {
      return _buildEmptyTimeline(
        fixture.statusShort == 'NS'
            ? 'Match has not started yet. Timeline updates live during the game!'
            : 'No events recorded for this match.',
      );
    }

    // Sort events chronologically
    final sortedEvents = List<MatchEvent>.from(events)
      ..sort((a, b) => a.elapsed.compareTo(b.elapsed));

    return Column(
      children: sortedEvents.map((event) {
        final isHome = event.teamId == fixture.homeTeam.id;
        return _buildTimelineItem(event, isHome);
      }).toList(),
    );
  }

  Widget _buildTimelineItem(MatchEvent event, bool isHome) {
    final iconData = _getEventIcon(event);
    final iconColor = _getEventColor(event);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side (Home team event)
          Expanded(
            child: isHome
                ? _buildEventContent(event, CrossAxisAlignment.end, textAlign: TextAlign.right)
                : const SizedBox.shrink(),
          ),
          // Center Minute Badge
          Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withOpacity(0.6), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${event.elapsed}'",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(iconData, size: 12, color: iconColor),
              ],
            ),
          ),
          // Right side (Away team event)
          Expanded(
            child: !isHome
                ? _buildEventContent(event, CrossAxisAlignment.start, textAlign: TextAlign.left)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventContent(MatchEvent event, CrossAxisAlignment align, {required TextAlign textAlign}) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (align == CrossAxisAlignment.start) ...[
              _buildEventBadge(event),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                event.playerName,
                textAlign: textAlign,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            if (align == CrossAxisAlignment.end) ...[
              const SizedBox(width: 6),
              _buildEventBadge(event),
            ],
          ],
        ),
        if (event.assistName != null && event.assistName!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            'assist: ${event.assistName}',
            textAlign: textAlign,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
        if (event.detail.isNotEmpty && !event.isGoal) ...[
          const SizedBox(height: 2),
          Text(
            event.detail,
            textAlign: textAlign,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _buildEventBadge(MatchEvent event) {
    if (event.isGoal) {
      return const Text('⚽', style: TextStyle(fontSize: 14));
    } else if (event.isYellowCard) {
      return Container(
        width: 10,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.amber[600],
          borderRadius: BorderRadius.circular(2),
        ),
      );
    } else if (event.isRedCard) {
      return Container(
        width: 10,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.red[600],
          borderRadius: BorderRadius.circular(2),
        ),
      );
    } else if (event.isSub) {
      return const Icon(Icons.swap_horiz, color: AppColors.primary, size: 16);
    } else {
      return const Icon(Icons.info_outline, color: Colors.blueAccent, size: 14);
    }
  }

  IconData _getEventIcon(MatchEvent event) {
    if (event.isGoal) return Icons.sports_soccer;
    if (event.isCard) return Icons.style;
    if (event.isSub) return Icons.swap_horiz;
    return Icons.fiber_manual_record;
  }

  Color _getEventColor(MatchEvent event) {
    if (event.isGoal) return AppColors.primary;
    if (event.isYellowCard) return Colors.amber;
    if (event.isRedCard) return Colors.redAccent;
    if (event.isSub) return Colors.blueAccent;
    return Colors.white54;
  }

  Widget _buildEmptyTimeline(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.timeline, size: 40, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
