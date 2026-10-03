import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/banner_ad_widget.dart';
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
    required this.teamLogo,
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.network(
              widget.teamLogo,
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.sports_soccer, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.teamName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
