import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/player.dart';

class PlayerDetailScreen extends StatelessWidget {
  final Player player;
  final String teamName;
  final String teamLogo;

  const PlayerDetailScreen({
    super.key,
    required this.player,
    this.teamName = '',
    this.teamLogo = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 16),
                  _buildQuickStatsGrid(),
                  const SizedBox(height: 16),
                  if (player.description.isNotEmpty) ...[
                    _buildBioCard(),
                    const SizedBox(height: 16),
                  ],
                  _buildCareerInfoCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.secondary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
        title: Text(
          player.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                  ],
                ),
              ),
            ),
            Center(
              child: player.photo.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: player.photo,
                      height: 200,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 100,
                        color: Colors.white24,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 100,
                      color: Colors.white24,
                    ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.background.withOpacity(0.95),
                  ],
                ),
              ),
            ),
            if (player.number.isNotEmpty)
              Positioned(
                top: 70,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: Text(
                    '#${player.number}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (teamLogo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 14.0),
                child: CachedNetworkImage(
                  imageUrl: teamLogo,
                  width: 44,
                  height: 44,
                  errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 40),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    teamName.isNotEmpty ? teamName : 'Club Player',
                    style: const TextStyle(fontSize: 13, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                player.position.isNotEmpty ? player.position : 'Player',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Player Details',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.flag,
                    'Nationality',
                    player.nationality.isNotEmpty ? player.nationality : 'N/A',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.calendar_today,
                    'Age',
                    player.age > 0 ? '${player.age} yrs' : 'N/A',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.height,
                    'Height',
                    player.height.isNotEmpty ? player.height : 'N/A',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.fitness_center,
                    'Weight',
                    player.weight.isNotEmpty ? player.weight : 'N/A',
                  ),
                ),
              ],
            ),
            if (player.birthDate.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildStatItem(
                Icons.cake,
                'Birth Date',
                player.birthDate.length >= 10 ? player.birthDate.substring(0, 10) : player.birthDate,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBioCard() {
    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.menu_book, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text(
                  'Biography',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              player.description,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareerInfoCard() {
    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.workspace_premium, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text(
                  'Profile Highlights',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBadgeRow(Icons.sports_soccer, 'Position Role', player.position.isNotEmpty ? player.position : 'Squad Member'),
            const Divider(color: Colors.white10, height: 16),
            _buildBadgeRow(Icons.check_circle_outline, 'Active Squad', 'First Team Roster'),
            const Divider(color: Colors.white10, height: 16),
            _buildBadgeRow(Icons.verified, 'Season Status', '2024/2025 Active'),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}
