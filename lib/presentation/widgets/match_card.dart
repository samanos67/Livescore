import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/fixture.dart';
import '../../core/constants/app_colors.dart';
import '../screens/match_detail/match_detail_screen.dart';
import '../../main.dart';

class MatchCard extends StatelessWidget {
  final Fixture fixture;

  const MatchCard({super.key, required this.fixture});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            interstitialAdService.showAdWithFrequencyCap(
              onDismissed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MatchDetailScreen(fixture: fixture)),
                );
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildMatchRow(),
                 if (fixture.isLive) ...[
                   const SizedBox(height: 12),
                   _buildLiveIndicator(),
                 ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (fixture.league.logoUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: fixture.league.logoUrl,
            width: 20,
            height: 20,
             errorWidget: (context, url, error) => const Icon(Icons.error, size: 20),
          ),
        const SizedBox(width: 8),
        Text(
          fixture.league.name,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Text(
          fixture.statusShort,
          style: TextStyle(
            color: fixture.isLive ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildTeam(fixture.homeTeam.name, fixture.homeTeam.logoUrl, true)),
        _buildScore(),
        Expanded(child: _buildTeam(fixture.awayTeam.name, fixture.awayTeam.logoUrl, false)),
      ],
    );
  }

  Widget _buildTeam(String name, String logo, bool isHome) {
    return Column(
      children: [
        CachedNetworkImage(
          imageUrl: logo,
          width: 48,
          height: 48,
          placeholder: (context, url) => const CircleAvatar(backgroundColor: Colors.grey, radius: 24),
           errorWidget: (context, url, error) => const Icon(Icons.shield, size: 48, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildScore() {
    if (fixture.statusShort == 'NS') {
      return Text(
        DateFormat('HH:mm').format(fixture.date),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${fixture.goalsHome ?? 0} - ${fixture.goalsAway ?? 0}',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
     return Row(
       mainAxisAlignment: MainAxisAlignment.center,
       children: [
         const Icon(Icons.play_circle_fill, color: AppColors.primary, size: 16),
         const SizedBox(width: 4),
         Text(
           '${fixture.elapsed}\'',
           style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
         ),
       ],
     );
  }
}
