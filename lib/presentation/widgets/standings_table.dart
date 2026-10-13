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
    if (standings.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No standings available', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.cardBackground,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          // ── Table Header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: AppColors.secondary,
            child: Row(
              children: [
                const SizedBox(
                  width: 28,
                  child: Text('#', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Team', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                _buildHeaderCell('P', 28),
                _buildHeaderCell('W', 24),
                _buildHeaderCell('D', 24),
                _buildHeaderCell('L', 24),
                _buildHeaderCell('GD', 30),
                _buildHeaderCell('PTS', 32, bold: true),
                const SizedBox(width: 4),
                const SizedBox(
                  width: 72,
                  child: Text('Form', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),

          // ── Table Rows ────────────────────────────────────────────────────
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: standings.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
            itemBuilder: (context, index) {
              final standing = standings[index];
              final isTopFour = index < 4;
              final isEuropa = index == 4;
              final isRelegation = index >= standings.length - 3;

              Color? rankColor;
              if (isTopFour) {
                rankColor = const Color(0xFF3B82F6); // UCL blue
              } else if (isEuropa) {
                rankColor = const Color(0xFFF59E0B); // UEL amber
              } else if (isRelegation) {
                rankColor = const Color(0xFFEF4444); // Relegation red
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      color: rankColor != null ? rankColor.withOpacity(0.06) : Colors.transparent,
                      child: Row(
                        children: [
                          // Rank with zone bar indicator
                          SizedBox(
                            width: 28,
                            child: Row(
                              children: [
                                if (rankColor != null)
                                  Container(
                                    width: 3,
                                    height: 14,
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: BoxDecoration(
                                      color: rankColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                Text(
                                  '${standing.rank}',
                                  style: TextStyle(
                                    fontWeight: isTopFour ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 13,
                                    color: rankColor ?? Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          CachedNetworkImage(
                            imageUrl: standing.team.logoUrl,
                            width: 22,
                            height: 22,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => const Icon(Icons.sports_soccer, size: 20, color: Colors.white30),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              standing.team.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStat('${standing.all.played}', 28),
                          _buildStat('${standing.all.win}', 24),
                          _buildStat('${standing.all.draw}', 24),
                          _buildStat('${standing.all.lose}', 24),
                          _buildStat(
                            '${standing.goalsDiff >= 0 ? '+' : ''}${standing.goalsDiff}',
                            30,
                            color: standing.goalsDiff > 0 ? Colors.green : (standing.goalsDiff < 0 ? Colors.redAccent : Colors.grey),
                          ),
                          _buildStat('${standing.points}', 32, bold: true, color: AppColors.primary),
                          const SizedBox(width: 4),
                          // Form last 5 dots
                          SizedBox(
                            width: 72,
                            child: _buildFormRow(standing.form),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // In-feed ad every 8 teams
                  if ((index + 1) % 8 == 0 && index != standings.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: BannerAdWidget(),
                    ),
                ],
              );
            },
          ),

          // ── Qualification Legend ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: AppColors.secondary.withOpacity(0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(const Color(0xFF3B82F6), 'Champions League'),
                _buildLegendItem(const Color(0xFFF59E0B), 'Europa League'),
                _buildLegendItem(const Color(0xFFEF4444), 'Relegation'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width, {bool bold = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: bold ? Colors.white : Colors.grey,
          fontSize: 11,
          fontWeight: bold ? FontWeight.bold : FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStat(String value, double width, {bool bold = false, Color? color}) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color ?? (bold ? Colors.white : Colors.white70),
        ),
      ),
    );
  }

  Widget _buildFormRow(String form) {
    if (form.isEmpty) {
      return const Center(child: Text('-', style: TextStyle(color: Colors.grey, fontSize: 10)));
    }
    final chars = form.split(',').join('').split('').take(5).toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: chars.map((c) {
        Color color;
        if (c.toUpperCase() == 'W') {
          color = const Color(0xFF10B981); // Green
        } else if (c.toUpperCase() == 'D') {
          color = const Color(0xFFF59E0B); // Amber
        } else {
          color = const Color(0xFFEF4444); // Red
        }
        return Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              c.toUpperCase(),
              style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

