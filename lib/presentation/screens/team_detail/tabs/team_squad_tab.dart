import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';

class TeamSquadTab extends ConsumerWidget {
  final int teamId;

  const TeamSquadTab({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPositionSection('Goalkeepers', 3),
        _buildPositionSection('Defenders', 8),
        _buildPositionSection('Midfielders', 8),
        _buildPositionSection('Forwards', 6),
      ],
    );
  }

  Widget _buildPositionSection(String position, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            position,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        ...List.generate(count, (index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.secondary,
                child: Text('${index + 1}'),
              ),
              title: Text('Player ${index + 1}'),
              subtitle: Text(position),
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        }),
      ],
    );
  }
}
