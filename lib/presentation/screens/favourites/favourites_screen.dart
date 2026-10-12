import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local/favorites_service.dart';
import '../../providers/team_provider.dart';
import '../../widgets/match_card.dart';
import '../team_detail/team_detail_screen.dart';
import '../../../domain/entities/news_article.dart';

// ─── Favourites Provider ──────────────────────────────────────────────────────
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<int>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<List<int>> {
  final _svc = FavoritesService();

  FavoritesNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    await _svc.init();
    state = _svc.getFavoriteTeams();
  }

  Future<void> toggle(int teamId) async {
    await _svc.toggleFavoriteTeam(teamId);
    state = _svc.getFavoriteTeams();
  }

  bool isFav(int teamId) => state.contains(teamId);
}

// ─── Favourites Screen ────────────────────────────────────────────────────────
class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIds = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teams'),
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No favourite teams yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the ♡ on any team page to follow them here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.hardEdge,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0088CC), Color(0xFF005f8a)],
          ),
        ),
        child: InkWell(
          onTap: () => launchUrl(Uri.parse(_telegramUrl), mode: LaunchMode.externalApplication),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.telegram, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📡 Watch Live Matches',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
        final next = fixtures.where((f) =>
          f.statusShort == 'NS' &&
          f.date.isAfter(DateTime.now())
        ).toList();
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
