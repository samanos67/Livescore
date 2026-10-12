import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../providers/team_provider.dart';
import '../../../../domain/entities/fixture.dart';
import '../../../../domain/entities/video_highlight.dart';
import '../../../../domain/entities/news_article.dart';

class TeamOverviewTab extends ConsumerWidget {
  final int teamId;
  final String teamName;

  const TeamOverviewTab({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamInfoAsync    = ref.watch(teamInfoProvider(teamId));
    final teamFixAsync     = ref.watch(teamFixturesProvider(teamId));
    final highlightsAsync  = ref.watch(teamHighlightsProvider(teamName));
    final newsAsync        = ref.watch(teamNewsProvider(teamName));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Team Info Card ────────────────────────────────────────────────────
        teamInfoAsync.when(
          data: (info) {
            if (info == null) return const SizedBox.shrink();
            return _TeamInfoCard(info: info);
          },
          loading: () => const _SectionLoader(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),

        // ── Next Fixture ──────────────────────────────────────────────────────
        teamFixAsync.when(
          data: (fixtures) {
            final upcoming = fixtures.where((f) =>
              f.fixture.status.short == 'NS' &&
              f.fixture.date.isAfter(DateTime.now())
            ).toList();
            if (upcoming.isEmpty) return const SizedBox.shrink();
            final next = upcoming.first;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Next Fixture'),
                _NextFixtureCard(fixture: next),
                const SizedBox(height: 16),
              ],
            );
          },
          loading: () => const _SectionLoader(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // ── Recent Form ───────────────────────────────────────────────────────
        teamFixAsync.when(
          data: (fixtures) {
            final finished = fixtures.where((f) =>
              f.fixture.status.short == 'FT'
            ).toList();
            if (finished.isEmpty) return const SizedBox.shrink();
            final last5   = finished.reversed.take(5).toList().reversed.toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Recent Form'),
                _FormRow(fixtures: last5, teamId: teamId),
                const SizedBox(height: 16),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // ── Highlights ────────────────────────────────────────────────────────
        highlightsAsync.when(
          data: (videos) {
            if (videos.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Latest Highlights'),
                _HighlightsRow(videos: videos),
                const SizedBox(height: 16),
              ],
            );
          },
          loading: () => const _SectionLoader(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // ── News ──────────────────────────────────────────────────────────────
        newsAsync.when(
          data: (articles) {
            if (articles.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Team News'),
                ...articles.take(5).map((a) => _NewsCard(article: a)),
              ],
            );
          },
          loading: () => const _SectionLoader(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
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

// ─────────────────────────────────────────────────────────────────────────────
// Team Info Card
// ─────────────────────────────────────────────────────────────────────────────
class _TeamInfoCard extends StatelessWidget {
  final dynamic info;
  const _TeamInfoCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Stadium banner or colour strip
          if (info.stadiumImage.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: info.stadiumImage,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  height: 160,
                  color: AppColors.secondary,
                  child: const Icon(Icons.stadium, size: 60, color: Colors.white30),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info grid
                Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: [
                    if (info.stadium.isNotEmpty)
                      _InfoChip(icon: Icons.stadium, label: info.stadium),
                    if (info.city.isNotEmpty)
                      _InfoChip(icon: Icons.location_on, label: info.city),
                    if (info.founded.isNotEmpty)
                      _InfoChip(icon: Icons.calendar_today, label: 'Est. ${info.founded}'),
                    if (info.manager.isNotEmpty)
                      _InfoChip(icon: Icons.person, label: info.manager),
                    if (info.stadiumCapacity.isNotEmpty)
                      _InfoChip(icon: Icons.people, label: '${info.stadiumCapacity} seats'),
                  ],
                ),

                // Description
                if (info.description.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _ExpandableText(text: info.description),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Flexible(child: Text(label, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}

class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'Show less' : 'Read more',
            style: const TextStyle(color: AppColors.primary, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Next Fixture Card
// ─────────────────────────────────────────────────────────────────────────────
class _NextFixtureCard extends StatelessWidget {
  final Fixture fixture;
  const _NextFixtureCard({required this.fixture});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE d MMM · HH:mm').format(fixture.fixture.date.toLocal());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(
              fixture.league.name,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TeamPill(name: fixture.teams.home.name, logo: fixture.teams.home.logo),
                const Text('VS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                _TeamPill(name: fixture.teams.away.name, logo: fixture.teams.away.logo),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamPill extends StatelessWidget {
  final String name;
  final String logo;
  const _TeamPill({required this.name, required this.logo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        logo.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: logo,
                width: 44,
                height: 44,
                errorWidget: (_, __, ___) => const Icon(Icons.sports_soccer, size: 40),
              )
            : const Icon(Icons.sports_soccer, size: 40),
        const SizedBox(height: 6),
        SizedBox(
          width: 90,
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form Row
// ─────────────────────────────────────────────────────────────────────────────
class _FormRow extends StatelessWidget {
  final List<Fixture> fixtures;
  final int teamId;
  const _FormRow({required this.fixtures, required this.teamId});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: fixtures.map((f) {
        final isHome   = f.teams.home.id == teamId;
        final homeGoals = f.goals.home ?? 0;
        final awayGoals = f.goals.away ?? 0;
        String result;
        Color color;
        if (isHome) {
          if (homeGoals > awayGoals)      { result = 'W'; color = Colors.green; }
          else if (homeGoals == awayGoals) { result = 'D'; color = Colors.orange; }
          else                             { result = 'L'; color = Colors.red; }
        } else {
          if (awayGoals > homeGoals)      { result = 'W'; color = Colors.green; }
          else if (awayGoals == homeGoals) { result = 'D'; color = Colors.orange; }
          else                             { result = 'L'; color = Colors.red; }
        }
        return Tooltip(
          message: isHome
              ? '${f.teams.home.name} ${homeGoals}-${awayGoals} ${f.teams.away.name}'
              : '${f.teams.home.name} ${homeGoals}-${awayGoals} ${f.teams.away.name}',
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(result, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Highlights horizontal scroll
// ─────────────────────────────────────────────────────────────────────────────
class _HighlightsRow extends StatelessWidget {
  final List<VideoHighlight> videos;
  const _HighlightsRow({required this.videos});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: videos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final v = videos[i];
          return GestureDetector(
            onTap: () => launchUrl(Uri.parse(v.url), mode: LaunchMode.externalApplication),
            child: SizedBox(
              width: 200,
              child: Card(
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (v.thumbnail.isNotEmpty)
                      CachedNetworkImage(imageUrl: v.thumbnail, fit: BoxFit.cover),
                    Container(color: Colors.black45),
                    const Center(child: Icon(Icons.play_circle_filled, color: Colors.white, size: 48)),
                    Positioned(
                      bottom: 6,
                      left: 6,
                      right: 6,
                      child: Text(
                        v.title,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// News Card
// ─────────────────────────────────────────────────────────────────────────────
class _NewsCard extends StatelessWidget {
  final NewsArticle article;
  const _NewsCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(article.url), mode: LaunchMode.externalApplication),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.image.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: article.image,
                    width: 80,
                    height: 70,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 80,
                      height: 70,
                      color: AppColors.secondary,
                      child: const Icon(Icons.article, color: Colors.white30),
                    ),
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.article, color: Colors.white30),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(article.source, style: const TextStyle(color: AppColors.primary, fontSize: 11)),
                        const Spacer(),
                        Text(article.timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic loader placeholder
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLoader extends StatelessWidget {
  const _SectionLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
