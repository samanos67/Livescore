import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/fixture.dart';
import '../../../../domain/entities/match_event.dart';
import '../../../../domain/entities/video_highlight.dart';
import '../../../providers/fixture_detail_provider.dart';
import '../../../providers/team_provider.dart';
import '../../live_tv/video_player_screen.dart';
import '../../../widgets/live_pitch_tracker_widget.dart';

class OverviewTab extends ConsumerStatefulWidget {
  final Fixture fixture;

  const OverviewTab({super.key, required this.fixture});

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab> {
  Fixture get fixture => widget.fixture;
  int _selectedViewMode = 0; // 0 = 2D Live Tracker, 1 = Highlights

  @override
  void initState() {
    super.initState();
    _selectedViewMode = widget.fixture.isLive ? 0 : 0;
  }

  Widget _buildViewModeToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedViewMode = 0),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedViewMode == 0 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sensors,
                      size: 15,
                      color: _selectedViewMode == 0 ? Colors.black : Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '2D LIVE TRACKER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _selectedViewMode == 0 ? Colors.black : Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedViewMode = 1),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedViewMode == 1 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      size: 15,
                      color: _selectedViewMode == 1 ? Colors.black : Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'HIGHLIGHTS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _selectedViewMode == 1 ? Colors.black : Colors.white70,
                        letterSpacing: 0.5,
                      ),
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

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(fixtureEventsProvider(fixture.id));
    final events = eventsAsync.value ?? [];

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildMatchHeaderCard(context),
        const SizedBox(height: 16),
        // ── 2D LIVE TRACKER: ONLY for LIVE matches! ───
        if (fixture.isLive) ...[
          _buildViewModeToggle(),
          if (_selectedViewMode == 0)
            LivePitchTrackerWidget(
              fixture: fixture,
              events: events,
            )
          else
            _buildMatchHighlightsCard(context, ref),
        ] else ...[
          // For completed or upcoming matches: directly show the Match Highlights card!
          _buildMatchHighlightsCard(context, ref),
        ],
        const SizedBox(height: 16),
        _buildMatchInfoCard(),
        _buildVenueCard(ref),
        const SizedBox(height: 20),
        eventsAsync.when(
          data: (events) {
            if (events.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('MATCH TIMELINE'),
                  const SizedBox(height: 12),
                  _buildTimelineSection(events),
                ],
              );
            }
            return _buildPreMatchOverview();
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => _buildPreMatchOverview(),
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

    final firstHalfEvents = sortedEvents.where((e) => e.elapsed <= 45).toList();
    final secondHalfEvents = sortedEvents.where((e) => e.elapsed > 45).toList();

    // Compute HT and FT scores
    final htHome = fixture.scoreHalftimeHome ??
        firstHalfEvents.where((e) => e.isGoal && e.teamId == fixture.homeTeam.id).length;
    final htAway = fixture.scoreHalftimeAway ??
        firstHalfEvents.where((e) => e.isGoal && e.teamId == fixture.awayTeam.id).length;

    final ftHome = fixture.goalsHome ??
        sortedEvents.where((e) => e.isGoal && e.teamId == fixture.homeTeam.id).length;
    final ftAway = fixture.goalsAway ??
        sortedEvents.where((e) => e.isGoal && e.teamId == fixture.awayTeam.id).length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          // 1. KICK OFF BADGE
          _buildTimelinePeriodBadge(
            title: 'KICK OFF',
            icon: Icons.sports,
            color: AppColors.primary,
            subtitle: DateFormat('HH:mm').format(fixture.date),
          ),

          // 2. 1st Half Events
          ...firstHalfEvents.map((event) {
            final isHome = event.teamId == fixture.homeTeam.id;
            return _buildTimelineItem(event, isHome);
          }),

          // 3. HALF TIME SEPARATOR
          if (secondHalfEvents.isNotEmpty ||
              fixture.isFinished ||
              ['HT', '2H'].contains(fixture.statusShort))
            _buildTimelinePeriodBadge(
              title: 'HALF TIME (HT)',
              icon: Icons.timer_outlined,
              color: Colors.amber,
              subtitle: '$htHome - $htAway',
            ),

          // 4. 2nd Half Events
          ...secondHalfEvents.map((event) {
            final isHome = event.teamId == fixture.homeTeam.id;
            return _buildTimelineItem(event, isHome);
          }),

          // 5. FULL TIME or LIVE STATUS
          if (fixture.isFinished)
            _buildTimelinePeriodBadge(
              title: 'FULL TIME (FT)',
              icon: Icons.flag,
              color: AppColors.primary,
              subtitle: 'Final: $ftHome - $ftAway',
            )
          else if (fixture.isLive)
            _buildTimelinePeriodBadge(
              title: 'LIVE NOW',
              icon: Icons.circle,
              color: Colors.redAccent,
              subtitle: "${fixture.elapsed ?? 45}' in play",
            ),
        ],
      ),
    );
  }

  Widget _buildTimelinePeriodBadge({
    required String title,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.white38, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(MatchEvent event, bool isHome) {
    final iconColor = _getEventColor(event);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side (Home team event)
          Expanded(
            child: isHome
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _buildEventContent(event, CrossAxisAlignment.end, textAlign: TextAlign.right),
                  )
                : const SizedBox.shrink(),
          ),

          // Center Timeline Spine with Minute Node
          SizedBox(
            width: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Vertical connecting spine line
                Positioned(
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    color: Colors.white12,
                  ),
                ),
                // Glowing circular minute node
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: iconColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${event.elapsed}'",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildSmallEventIcon(event),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right side (Away team event)
          Expanded(
            child: !isHome
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _buildEventContent(event, CrossAxisAlignment.start, textAlign: TextAlign.left),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventContent(MatchEvent event, CrossAxisAlignment align, {required TextAlign textAlign}) {
    if (event.isSub) {
      final playerIn = event.playerName;
      final playerOut = event.assistName ?? event.comments ?? 'Teammate';
      return Column(
        crossAxisAlignment: align,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (align == CrossAxisAlignment.start) ...[
                const Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 14),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  playerIn,
                  textAlign: textAlign,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (align == CrossAxisAlignment.end) ...[
                const SizedBox(width: 4),
                const Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 14),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (align == CrossAxisAlignment.start) ...[
                const Icon(Icons.arrow_downward, color: Colors.redAccent, size: 12),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  playerOut,
                  textAlign: textAlign,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ),
              if (align == CrossAxisAlignment.end) ...[
                const SizedBox(width: 4),
                const Icon(Icons.arrow_downward, color: Colors.redAccent, size: 12),
              ],
            ],
          ),
        ],
      );
    }

    if (event.isGoal) {
      final isPenalty = event.detail.toLowerCase().contains('pen');
      final isOwnGoal = event.detail.toLowerCase().contains('own');
      return Column(
        crossAxisAlignment: align,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (align == CrossAxisAlignment.start) ...[
                const Text('⚽', style: TextStyle(fontSize: 14)),
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
              if (isPenalty) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text('P', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
              if (isOwnGoal) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text('OG', style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
              if (align == CrossAxisAlignment.end) ...[
                const SizedBox(width: 6),
                const Text('⚽', style: TextStyle(fontSize: 14)),
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
        ],
      );
    }

    // Card or generic event
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
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
        if (event.detail.isNotEmpty) ...[
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

  Widget _buildSmallEventIcon(MatchEvent event) {
    if (event.isGoal) {
      return const Text('⚽', style: TextStyle(fontSize: 8));
    } else if (event.isYellowCard) {
      return Container(
        width: 6,
        height: 8,
        decoration: BoxDecoration(color: Colors.amber[600], borderRadius: BorderRadius.circular(1)),
      );
    } else if (event.isRedCard) {
      return Container(
        width: 6,
        height: 8,
        decoration: BoxDecoration(color: Colors.red[600], borderRadius: BorderRadius.circular(1)),
      );
    } else if (event.isSub) {
      return const Icon(Icons.swap_horiz, size: 10, color: AppColors.primary);
    }
    return const Icon(Icons.fiber_manual_record, size: 8, color: Colors.white54);
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

  Color _getEventColor(MatchEvent event) {
    if (event.isGoal) return AppColors.primary;
    if (event.isYellowCard) return Colors.amber;
    if (event.isRedCard) return Colors.redAccent;
    if (event.isSub) return Colors.blueAccent;
    return Colors.white54;
  }

  Widget _buildMatchInfoCard() {
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
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'MATCH DETAILS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Competition', fixture.league.name),
          if (fixture.league.round != null && fixture.league.round!.isNotEmpty)
            _buildDetailRow('Stage / Round', fixture.league.round!),
          if (fixture.referee.isNotEmpty && fixture.referee != 'Unknown')
            _buildDetailRow('Referee', fixture.referee),
          _buildDetailRow(
            'Date & Time',
            DateFormat('EEEE, d MMMM yyyy • HH:mm').format(fixture.date),
          ),
          _buildDetailRow('Status', fixture.statusLong),
        ],
      ),
    );
  }

  Widget _buildVenueCard(WidgetRef ref) {
    final homeInfoAsync = ref.watch(teamInfoProvider(fixture.homeTeam.id));
    return homeInfoAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (info) {
        final stadium = info?.stadium;
        if (stadium == null || stadium.isEmpty) return const SizedBox.shrink();
        final city = info?.city ?? '';
        final country = info?.country ?? '';
        final location = [city, country].where((s) => s.isNotEmpty).join(', ');
        final capacity = info?.stadiumCapacity ?? '';

        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.stadium, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'VENUE & STADIUM',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Stadium', stadium),
              if (location.isNotEmpty) _buildDetailRow('Location', location),
              if (capacity.isNotEmpty) _buildDetailRow('Capacity', '$capacity seats'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreMatchOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('PRE-MATCH PREVIEW & FORM'),
        const SizedBox(height: 12),
        // Form comparison card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fixture.homeTeam.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildFormDot('W', Colors.green),
                            const SizedBox(width: 4),
                            _buildFormDot('W', Colors.green),
                            const SizedBox(width: 4),
                            _buildFormDot('D', Colors.amber),
                            const SizedBox(width: 4),
                            _buildFormDot('W', Colors.green),
                            const SizedBox(width: 4),
                            _buildFormDot('L', Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('FORM', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          fixture.awayTeam.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildFormDot('D', Colors.amber),
                            const SizedBox(width: 4),
                            _buildFormDot('W', Colors.green),
                            const SizedBox(width: 4),
                            _buildFormDot('L', Colors.red),
                            const SizedBox(width: 4),
                            _buildFormDot('W', Colors.green),
                            const SizedBox(width: 4),
                            _buildFormDot('W', Colors.green),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 10),
              // Win Probability indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('WIN PROBABILITY', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('48% ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                      Expanded(
                        flex: 48,
                        child: Container(height: 6, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(3))),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 24,
                        child: Container(height: 6, decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(3))),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 28,
                        child: Container(height: 6, decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(3))),
                      ),
                      const Text(' 28%', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Home Win', style: TextStyle(color: Colors.grey, fontSize: 10)),
                      Text('Draw 24%', style: TextStyle(color: Colors.grey, fontSize: 10)),
                      Text('Away Win', style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Lineup & notification hint
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.sports_soccer, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Probable XI & squad rosters are ready in the Lineups tab. Official lineups confirmed ~60m before kickoff.',
                  style: TextStyle(color: Colors.grey[300], fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormDot(String label, Color color) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
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

  Widget _buildMatchHighlightsCard(BuildContext context, WidgetRef ref) {
    final matchQuery = '${fixture.homeTeam.name} vs ${fixture.awayTeam.name}';
    final highlightAsync = ref.watch(fixtureHighlightProvider(matchQuery));

    return highlightAsync.when(
      loading: () => Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF14161E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
              SizedBox(height: 12),
              Text(
                'Searching match highlights...',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      error: (_, __) => _buildHighlightDisplay(
        context,
        VideoHighlight(
          videoId: '',
          title: '$matchQuery Highlights & Goals',
          thumbnail: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=800&q=80',
          channel: 'Official Highlights',
          publishedAt: '',
          url: '',
        ),
      ),
      data: (highlight) {
        final video = highlight ?? VideoHighlight(
          videoId: '',
          title: '$matchQuery Highlights & Goals',
          thumbnail: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=800&q=80',
          channel: 'Official Highlights',
          publishedAt: '',
          url: '',
        );
        return _buildHighlightDisplay(context, video);
      },
    );
  }

  Widget _buildHighlightDisplay(BuildContext context, VideoHighlight video) {
    final scoreText = (fixture.goalsHome != null && fixture.goalsAway != null)
        ? '${fixture.goalsHome} - ${fixture.goalsAway}'
        : (fixture.isFinished ? 'FT' : 'VS');

    final matchBannerText = '${fixture.homeTeam.name.toUpperCase()} VS ${fixture.awayTeam.name.toUpperCase()}';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14161E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. MATCH HIGHLIGHTS Header matching reference
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'MATCH HIGHLIGHTS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow, color: Colors.redAccent, size: 12),
                      SizedBox(width: 3),
                      Text(
                        'IN-APP HD',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. 16:9 Video Thumbnail Frame with Center Play Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(
                    videoId: video.videoId.isNotEmpty ? video.videoId : null,
                    streamUrl: video.url.isNotEmpty ? video.url : null,
                    title: video.title.isNotEmpty
                        ? video.title
                        : '${fixture.homeTeam.name} vs ${fixture.awayTeam.name} Highlights',
                    matchQuery: '${fixture.homeTeam.name} vs ${fixture.awayTeam.name}',
                  ),
                ),
              );
            },
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: video.thumbnail.isNotEmpty
                        ? video.thumbnail
                        : 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=800&q=80',
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: Colors.black26,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFF1B202D),
                      child: const Center(
                        child: Icon(Icons.sports_soccer, size: 60, color: Colors.white24),
                      ),
                    ),
                  ),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),

                  Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.65),
                        border: Border.all(color: Colors.white.withOpacity(0.9), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 16,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),

                  if (video.channel.isNotEmpty)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          video.channel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 3. Bottom Match Name Bar and Score
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(
                    videoId: video.videoId.isNotEmpty ? video.videoId : null,
                    streamUrl: video.url.isNotEmpty ? video.url : null,
                    title: video.title.isNotEmpty
                        ? video.title
                        : '${fixture.homeTeam.name} vs ${fixture.awayTeam.name} Highlights',
                    matchQuery: '${fixture.homeTeam.name} vs ${fixture.awayTeam.name}',
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF0F1118),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          matchBannerText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          video.title.isNotEmpty ? video.title : 'Tap to watch match recap in-app',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      scoreText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
