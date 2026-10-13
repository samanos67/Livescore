import 'package:flutter/material.dart';
import '../../../domain/entities/fixture.dart';
import '../../../core/constants/app_colors.dart';
import 'tabs/overview_tab.dart';
import 'tabs/stats_tab.dart';
import 'tabs/lineups_tab.dart';
import 'tabs/h2h_tab.dart';
import '../live_tv/video_player_screen.dart';
import '../../providers/favorites_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/banner_ad_widget.dart';

class MatchDetailScreen extends ConsumerStatefulWidget {
  final Fixture fixture;

  const MatchDetailScreen({super.key, required this.fixture});

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openLiveStream(BuildContext context) {
    final title = '${widget.fixture.homeTeam.name} vs ${widget.fixture.awayTeam.name}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          title: title,
          matchQuery: '${widget.fixture.homeTeam.name} vs ${widget.fixture.awayTeam.name} live stream',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(widget.fixture.homeTeam.id) ||
        favorites.contains(widget.fixture.awayTeam.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.fixture.homeTeam.name} vs ${widget.fixture.awayTeam.name}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.secondary,
        actions: [
          if (widget.fixture.isLive)
            IconButton(
              icon: const Icon(Icons.live_tv, color: Colors.redAccent),
              tooltip: 'Watch Live Stream',
              onPressed: () => _openLiveStream(context),
            ),
          IconButton(
            icon: Icon(isFavorite ? Icons.star : Icons.star_border),
            color: isFavorite ? AppColors.primary : Colors.grey,
            onPressed: () {
              ref.read(favoritesProvider.notifier).toggleFavorite(widget.fixture.homeTeam.id);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          isScrollable: false,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Stats'),
            Tab(text: 'Lineups'),
            Tab(text: 'H2H'),
          ],
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
      floatingActionButton: widget.fixture.isLive
          ? FloatingActionButton.extended(
              backgroundColor: Colors.redAccent,
              icon: const Icon(Icons.play_circle_fill, color: Colors.white),
              label: const Text(
                'WATCH LIVE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              onPressed: () => _openLiveStream(context),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          OverviewTab(fixture: widget.fixture),
          StatsTab(fixture: widget.fixture),
          LineupsTab(fixture: widget.fixture),
          H2HTab(fixture: widget.fixture),
        ],
      ),
    );
  }
}
