import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/team_provider.dart';
import '../../widgets/match_card.dart';
import '../../../domain/entities/news_article.dart';
import '../team_detail/team_detail_screen.dart';
import '../common/in_app_article_screen.dart';

import '../../providers/favorites_provider.dart';
import '../onboarding/onboarding_screen.dart';
import '../../widgets/banner_ad_widget.dart';
export '../../providers/favorites_provider.dart';

// ─── Favourites Screen ────────────────────────────────────────────────────────
class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIds = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 28,
                height: 28,
              ),
            ),
            const SizedBox(width: 10),
            const Text('My Teams', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              for (final id in favIds) {
                ref.invalidate(teamInfoProvider(id));
                ref.invalidate(teamFixturesProvider(id));
              }
              ref.invalidate(generalNewsProvider);
            },
          ),
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(),
      body: favIds.isEmpty
          ? const _EmptyState()
          : RefreshIndicator(
              onRefresh: () async {
                for (final id in favIds) {
                  ref.invalidate(teamInfoProvider(id));
                  ref.invalidate(teamFixturesProvider(id));
                }
                ref.invalidate(generalNewsProvider);
              },
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  // ── Favourite Teams Header Cards ──────────────────────────
                  const _SectionTitle('Your Teams'),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: favIds.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => _FavTeamChip(
                        teamId: favIds[i],
                        onTap: (name) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeamDetailScreen(teamId: favIds[i], teamName: name),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Telegram Livestream Section ───────────────────────────
                  const _TelegramCard(),
                  const SizedBox(height: 16),

                  // ── Upcoming Fixtures ─────────────────────────────────────
                  const _SectionTitle('Upcoming Fixtures'),
                  ...favIds.map((id) => _TeamNextFixture(teamId: id)),
                  const SizedBox(height: 16),

                  // ── Recent Results ────────────────────────────────────────
                  const _SectionTitle('Recent Results'),
                  ...favIds.map((id) => _TeamRecentResults(teamId: id)),
                  const SizedBox(height: 16),

                  // ── Football News ─────────────────────────────────────────
                  const _SectionTitle('Latest Football News'),
                  const _NewsSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state when no favourites
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/no_favorites.png',
                width: 160,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No favourite teams yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Follow your favourite clubs to get instant match updates, live scores, and news here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline, color: Colors.black),
              label: const Text(
                'PICK TEAMS TO FOLLOW',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OnboardingScreen(isInitialLaunch: false),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Favourite team chip (horizontal strip)
// ─────────────────────────────────────────────────────────────────────────────
class _FavTeamChip extends ConsumerWidget {
  final int teamId;
  final Function(String name) onTap;
  const _FavTeamChip({required this.teamId, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(teamInfoProvider(teamId));
    return infoAsync.when(
      loading: () => const SizedBox(
        width: 90,
        child: Card(child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (_, __) => const SizedBox(width: 90),
      data: (info) {
        final name = info?.name ?? 'Team $teamId';
        final logo = info?.logo ?? '';
        return GestureDetector(
          onTap: () => onTap(name),
          child: SizedBox(
            width: 90,
            child: Card(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  logo.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: logo,
                          width: 50,
                          height: 50,
                          errorWidget: (_, __, ___) => const Icon(Icons.sports_soccer, size: 40),
                        )
                      : const Icon(Icons.sports_soccer, size: 40),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Telegram Livestream Card
// ─────────────────────────────────────────────────────────────────────────────
class _TelegramCard extends StatelessWidget {
  const _TelegramCard();
  static const _telegramUrl = 'https://t.me/your_livescore_channel'; // ← update this

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/telegram_banner.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.88),
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () => launchUrl(Uri.parse(_telegramUrl), mode: LaunchMode.externalApplication),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0088CC).withOpacity(0.85),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0088CC).withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.telegram, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Watch Live Matches',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.sensors, color: AppColors.primary, size: 16),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Join our Telegram channel for live stream links posted before every match.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Team next fixture block
// ─────────────────────────────────────────────────────────────────────────────
class _TeamNextFixture extends ConsumerWidget {
  final int teamId;
  const _TeamNextFixture({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fixturesAsync = ref.watch(teamFixturesProvider(teamId));
    return fixturesAsync.when(
      loading: () => const SizedBox(height: 60, child: Center(child: LinearProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
      data: (fixtures) {
        final next = fixtures.where((f) {
          final s = f.statusShort;
          return (s == 'NS' || s == 'TBD' || s == 'TIMED' || s == 'SCHEDULED') &&
              f.date.isAfter(DateTime.now());
        }).toList();
        next.sort((a, b) => a.date.compareTo(b.date));
        if (next.isEmpty) return const SizedBox.shrink();
        return MatchCard(fixture: next.first);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Team recent results (last 2)
// ─────────────────────────────────────────────────────────────────────────────
class _TeamRecentResults extends ConsumerWidget {
  final int teamId;
  const _TeamRecentResults({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fixturesAsync = ref.watch(teamFixturesProvider(teamId));
    return fixturesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (fixtures) {
        final finished = fixtures
            .where((f) => f.isFinished)
            .toList()
            .reversed
            .take(2)
            .toList();
        if (finished.isEmpty) return const SizedBox.shrink();
        return Column(
          children: finished.map((f) => MatchCard(fixture: f)).toList(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// News section
// ─────────────────────────────────────────────────────────────────────────────
class _NewsSection extends ConsumerWidget {
  const _NewsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(generalNewsProvider);
    return newsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (articles) {
        return Column(
          children: articles.take(8).map((a) => _ArticleRow(article: a)).toList(),
        );
      },
    );
  }
}

class _ArticleRow extends StatelessWidget {
  final NewsArticle article;
  const _ArticleRow({required this.article});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InAppArticleScreen(article: article),
          ),
        ),
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
                    height: 65,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 80, height: 65,
                      color: AppColors.secondary,
                      child: const Icon(Icons.article, color: Colors.white30),
                    ),
                  ),
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
// Section title
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }
}
