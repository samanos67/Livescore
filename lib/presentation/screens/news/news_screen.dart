import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/news_article.dart';
import '../../providers/team_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/banner_ad_widget.dart';
import '../common/in_app_article_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../../../services/notification_service.dart';

class NewsScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const NewsScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _sendTestAlert(List<NewsArticle> articles) async {
    final article = articles.isNotEmpty ? articles.first : null;
    await NotificationService().testSendNewsNotification(article);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.notifications_active, color: AppColors.primary, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Push notification sent! Tap it from your status bar to test returning to the app.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.secondary,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final worldNewsAsync = ref.watch(generalNewsProvider);
    final myTeamsNewsAsync = ref.watch(favoriteTeamsNewsProvider);
    final transferNewsAsync = ref.watch(transferNewsProvider);
    final favCount = ref.watch(favoritesProvider).length;

    return Scaffold(
      backgroundColor: AppColors.background,
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
            const Text(
              'Football News',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          // Push notification test button
          IconButton(
            icon: const Icon(Icons.notification_add_outlined),
            tooltip: 'Send Test News Notification',
            onPressed: () {
              final articles = worldNewsAsync.value ?? [];
              _sendTestAlert(articles);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh News',
            onPressed: () {
              ref.invalidate(generalNewsProvider);
              ref.invalidate(favoriteTeamsNewsProvider);
              ref.invalidate(transferNewsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            const Tab(text: 'World News'),
            Tab(text: 'My Teams ($favCount)'),
            const Tab(text: 'Transfers'),
          ],
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: World Football News ─────────────────────────────────────
          _buildNewsList(
            asyncValue: worldNewsAsync,
            onRefresh: () async => ref.invalidate(generalNewsProvider),
            emptyMessage: 'No world news available at the moment.',
          ),

          // ── Tab 2: Followed Teams News ─────────────────────────────────────
          favCount == 0
              ? _buildNoFavoritesPrompt()
              : _buildNewsList(
                  asyncValue: myTeamsNewsAsync,
                  onRefresh: () async => ref.invalidate(favoriteTeamsNewsProvider),
                  emptyMessage: 'No recent news found for your followed clubs. Check back soon or follow more clubs!',
                  showAddClubsBanner: true,
                ),

          // ── Tab 3: Transfers & Rumours ────────────────────────────────────
          _buildNewsList(
            asyncValue: transferNewsAsync,
            onRefresh: () async => ref.invalidate(transferNewsProvider),
            emptyMessage: 'No transfer rumors at the moment.',
          ),
        ],
      ),
    );
  }

  Widget _buildNoFavoritesPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.favorite_border, size: 54, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Followed Clubs Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Follow your favourite football clubs to get breaking team news, transfer updates & match notifications.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle, color: Colors.black),
              label: const Text(
                'PICK CLUBS TO FOLLOW',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen(isInitialLaunch: false)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsList({
    required AsyncValue<List<NewsArticle>> asyncValue,
    required Future<void> Function() onRefresh,
    required String emptyMessage,
    bool showAddClubsBanner = false,
  }) {
    return asyncValue.when(
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Failed to load news articles',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                err.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 18, color: Colors.black),
                label: const Text('RETRY', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: onRefresh,
              ),
            ],
          ),
        ),
      ),
      data: (articles) {
        if (articles.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final heroArticle = articles.first;
        final listArticles = articles.length > 1 ? articles.sublist(1) : <NewsArticle>[];

        return RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (showAddClubsBanner)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Showing news for your followed clubs',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OnboardingScreen(isInitialLaunch: false)),
                        ),
                        child: const Text('Edit', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                      ),
                    ],
                  ),
                ),

              // ── Featured Top Breaking Story ───────────────────────────────
              _FeaturedNewsCard(
                article: heroArticle,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => InAppArticleScreen(article: heroArticle)),
                ),
              ),
              const SizedBox(height: 14),

              // ── Section Title ─────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      'LATEST HEADLINES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.feed_outlined, size: 16, color: Colors.grey),
                  ],
                ),
              ),

              // ── Article List ──────────────────────────────────────────────
              ...listArticles.map(
                (article) => _NewsCard(
                  article: article,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => InAppArticleScreen(article: article)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Featured Hero Card (Top Story)
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturedNewsCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;

  const _FeaturedNewsCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            Stack(
              children: [
                if (article.image.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: article.image,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 180,
                      color: AppColors.secondary,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 180,
                      color: AppColors.secondary,
                      child: const Icon(Icons.sports_soccer, size: 60, color: Colors.white24),
                    ),
                  )
                else
                  Container(
                    height: 150,
                    color: AppColors.secondary,
                    child: const Center(
                      child: Icon(Icons.newspaper, size: 60, color: Colors.white24),
                    ),
                  ),

                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.85),
                        ],
                      ),
                    ),
                  ),
                ),

                // Source Badge & Breaking Tag
                Positioned(
                  top: 12,
                  left: 12,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bolt, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'BREAKING',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          article.source,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  if (article.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      article.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        article.timeAgo,
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      const Spacer(),
                      const Text(
                        'Read Full Article',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Standard News Card
// ─────────────────────────────────────────────────────────────────────────────
class _NewsCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;

  const _NewsCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: article.image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: article.image,
                        width: 90,
                        height: 75,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 90,
                          height: 75,
                          color: AppColors.secondary,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 90,
                          height: 75,
                          color: AppColors.secondary,
                          child: const Icon(Icons.newspaper, color: Colors.white24),
                        ),
                      )
                    : Container(
                        width: 90,
                        height: 75,
                        color: AppColors.secondary,
                        child: const Icon(Icons.newspaper, color: Colors.white24),
                      ),
              ),
              const SizedBox(width: 12),

              // Title and Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            article.source,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          article.timeAgo,
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
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
