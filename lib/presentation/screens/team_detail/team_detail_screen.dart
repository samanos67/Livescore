import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/banner_ad_widget.dart';
import '../favourites/favourites_screen.dart';
import 'tabs/team_overview_tab.dart';
import 'tabs/team_fixtures_tab.dart';
import 'tabs/team_squad_tab.dart';
import 'tabs/team_stats_tab.dart';

class TeamDetailScreen extends ConsumerStatefulWidget {
  final int teamId;
  final String teamName;
  final String teamLogo;

  const TeamDetailScreen({
    super.key,
    required this.teamId,
    required this.teamName,
    this.teamLogo = '',
  });

  @override
  ConsumerState<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends ConsumerState<TeamDetailScreen>
    with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final isFav  = ref.watch(favoritesProvider).contains(widget.teamId);
    final favNot = ref.read(favoritesProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.teamLogo.isNotEmpty)
              CachedNetworkImage(
                imageUrl: widget.teamLogo,
                width: 28,
                height: 28,
                errorWidget: (_, __, ___) => const Icon(Icons.sports_soccer, size: 24),
              )
            else
              const Icon(Icons.sports_soccer, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.teamName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // ── Favourite heart button ──────────────────────────────────────
          IconButton(
            tooltip: isFav ? 'Remove from My Teams' : 'Add to My Teams',
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(isFav),
                color: isFav ? Colors.redAccent : null,
              ),
            ),
            onPressed: () async {
              await favNot.toggle(widget.teamId);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFav
                        ? '${widget.teamName} removed from My Teams'
                        : '${widget.teamName} added to My Teams ❤️',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Fixtures'),
            Tab(text: 'Squad'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: Column(
        children: [
          const BannerAdWidget(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                TeamOverviewTab(teamId: widget.teamId, teamName: widget.teamName),
                TeamFixturesTab(teamId: widget.teamId),
                TeamSquadTab(teamId: widget.teamId),
                TeamStatsTab(teamId: widget.teamId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
