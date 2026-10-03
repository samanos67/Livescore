import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/standing.dart';
import '../../core/constants/app_colors.dart';
import '../screens/team_detail/team_detail_screen.dart';
import 'banner_ad_widget.dart';

class StandingsTable extends StatelessWidget {
  final List<Standing> standings;

  const StandingsTable({super.key, required this.standings});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: standings.length,
      itemBuilder: (context, index) {
        final standing = standings[index];
        final isTopFour = index < 4;
        final isRelegation = index >= standings.length - 3;
        
        Color? rowColor;
        if (isTopFour) {
          rowColor = AppColors.primary.withOpacity(0.1);
        } else if (isRelegation) {
          rowColor = Colors.red.withOpacity(0.1);
        }

        return Column(
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeamDetailScreen(
                      teamId: standing.team.id,
                      teamName: standing.team.name,
                      teamLogo: standing.team.logoUrl,
                    ),
                  ),
                );
              },
              child: Container(
                color: rowColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '${standing.rank}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    CachedNetworkImage(
                      imageUrl: standing.team.logoUrl,
                      width: 24,
                      height: 24,
                      errorWidget: (context, url, error) => const Icon(Icons.sports_soccer, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        standing.team.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    _buildStat('${standing.all.played}', 40),
                    _buildStat('${standing.all.win}', 30),
                    _buildStat('${standing.all.draw}', 30),
                    _buildStat('${standing.all.lose}', 30),
                    _buildStat('${standing.goalsDiff}', 40),
                    _buildStat(
                      '${standing.points}',
                      40,
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),
            // Add ad every 5 teams
            if ((index + 1) % 5 == 0 && index != standings.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: BannerAdWidget(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStat(String value, double width, {bool bold = false}) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
