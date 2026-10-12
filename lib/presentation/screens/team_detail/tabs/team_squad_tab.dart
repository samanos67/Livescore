import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../providers/team_provider.dart';
import '../../../../domain/entities/player.dart';

class TeamSquadTab extends ConsumerWidget {
  final int teamId;

  const TeamSquadTab({super.key, required this.teamId});

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
        return _SquadList(players: players);
      },
    );
  }
}

class _SquadList extends StatelessWidget {
  final List<Player> players;
  const _SquadList({required this.players});

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
          ...entry.value.map((p) => _PlayerRow(player: p)),
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
  const _PlayerRow({required this.player});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _PlayerAvatar(photoUrl: player.photo, number: player.number),
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
        trailing: player.height.isNotEmpty
            ? Text(player.height, style: const TextStyle(fontSize: 12, color: Colors.grey))
            : null,
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  final String photoUrl;
  final String number;
  const _PlayerAvatar({required this.photoUrl, required this.number});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.secondary,
          child: photoUrl.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: photoUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(Icons.person, color: Colors.white60),
                  ),
                )
              : const Icon(Icons.person, color: Colors.white60),
        ),
        if (number.isNotEmpty)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                number,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
