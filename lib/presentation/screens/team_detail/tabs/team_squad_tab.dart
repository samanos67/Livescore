import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../providers/team_provider.dart';
import '../../../../domain/entities/player.dart';

import '../../player_detail/player_detail_screen.dart';

class TeamSquadTab extends ConsumerWidget {
  final int teamId;
  final String teamName;
  final String teamLogo;

  const TeamSquadTab({
    super.key,
    required this.teamId,
    this.teamName = '',
    this.teamLogo = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final squadAsync = ref.watch(teamSquadProvider(teamId));

    return squadAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Could not load squad', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(teamSquadProvider(teamId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (players) {
        if (players.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Squad not available', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return _SquadList(
          players: players,
          teamName: teamName,
          teamLogo: teamLogo,
        );
      },
    );
  }
}

class _SquadList extends StatelessWidget {
  final List<Player> players;
  final String teamName;
  final String teamLogo;

  const _SquadList({
    required this.players,
    this.teamName = '',
    this.teamLogo = '',
  });

  static const _positionOrder = ['Goalkeeper', 'Defender', 'Midfielder', 'Forward'];

  Map<String, List<Player>> _groupPlayers() {
    final Map<String, List<Player>> groups = {};
    for (final pos in _positionOrder) {
      groups[pos] = [];
    }
    groups['Other'] = [];

    for (final player in players) {
      final pos = player.position;
      if (pos.contains('oalkeeper') || pos == 'GK') {
        groups['Goalkeeper']!.add(player);
      } else if (pos.contains('efend') || pos == 'CB' || pos == 'LB' || pos == 'RB' || pos == 'D') {
        groups['Defender']!.add(player);
      } else if (pos.contains('idfiel') || pos == 'CM' || pos == 'CAM' || pos == 'DM' || pos == 'M') {
        groups['Midfielder']!.add(player);
      } else if (pos.contains('orward') || pos.contains('triker') || pos == 'LW' || pos == 'RW' || pos == 'F') {
        groups['Forward']!.add(player);
      } else {
        groups['Other']!.add(player);
      }
    }

    // Remove empty groups (including 'Other' if empty)
    groups.removeWhere((key, list) => list.isEmpty);
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupPlayers();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final entry in grouped.entries) ...[
          _PositionHeader(title: entry.key, count: entry.value.length),
          ...entry.value.map(
            (p) => _PlayerRow(
              player: p,
              teamName: teamName,
              teamLogo: teamLogo,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _PositionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _PositionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          Text(
            '$count players',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final Player player;
  final String teamName;
  final String teamLogo;

  const _PlayerRow({
    required this.player,
    this.teamName = '',
    this.teamLogo = '',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlayerDetailScreen(
                player: player,
                teamName: teamName,
                teamLogo: teamLogo,
              ),
            ),
          );
        },
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: _PlayerAvatar(photoUrl: player.photo, number: player.number, name: player.name),
          title: Text(
            player.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Row(
            children: [
              if (player.nationality.isNotEmpty) ...[
                Text(player.nationality, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 8),
              ],
              if (player.age > 0)
                Text('${player.age} yrs', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (player.height.isNotEmpty)
                Text(player.height, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 18, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  final String photoUrl;
  final String number;
  final String name;

  const _PlayerAvatar({
    required this.photoUrl,
    required this.number,
    this.name = '',
  });

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = photoUrl.isNotEmpty
        ? photoUrl
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name.isNotEmpty ? name : "Player")}&background=1E1E1E&color=00D563&size=160&bold=true';

    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.secondary,
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: effectiveUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppColors.secondary,
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0] : 'P',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.secondary,
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0] : 'P',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (number.isNotEmpty)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                number,
                style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
