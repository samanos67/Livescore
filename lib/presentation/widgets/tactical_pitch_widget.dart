import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/lineup.dart';

class TacticalPitchWidget extends StatelessWidget {
  final Lineup lineup;
  final bool isHome;

  const TacticalPitchWidget({
    super.key,
    required this.lineup,
    this.isHome = true,
  });

  @override
  Widget build(BuildContext context) {
    final rows = _organizePlayersIntoRows();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 380,
      decoration: BoxDecoration(
        color: const Color(0xFF1B4D2E), // Rich pitch turf green
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Custom pitch lines
            CustomPaint(
              size: Size.infinite,
              painter: _PitchPainter(),
            ),
            // Formation badge overlay
            Positioned(
              top: 10,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isHome ? AppColors.primary : Colors.orangeAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Formation: ${lineup.formation.isEmpty ? "4-3-3" : lineup.formation}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Player rows (from GK at bottom to Strikers at top)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: rows.reversed.map((rowPlayers) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: rowPlayers.map((player) {
                      return _buildPlayerNode(player);
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerNode(Player player) {
    final lastName = _extractLastName(player.name);
    final isGk = player.pos == 'G' || player.number == 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isGk
                ? Colors.amber[700]
                : (isHome ? AppColors.primary : const Color(0xFFE53935)),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            player.number != null ? '${player.number}' : '',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(4),
          ),
          constraints: const BoxConstraints(maxWidth: 68),
          child: Text(
            lastName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _extractLastName(String fullName) {
    if (fullName.isEmpty) return 'Player';
    final parts = fullName.trim().split(' ');
    return parts.last;
  }

  List<List<Player>> _organizePlayersIntoRows() {
    final players = lineup.startXI;
    if (players.isEmpty) return [];

    // Check if players have grid coordinates (e.g. "1:1", "2:3")
    final hasGrid = players.any((p) => p.grid != null && p.grid!.contains(':'));
    if (hasGrid) {
      final Map<int, List<Player>> rowMap = {};
      for (var p in players) {
        int rowIndex = 1;
        if (p.grid != null && p.grid!.contains(':')) {
          final rowStr = p.grid!.split(':')[0];
          rowIndex = int.tryParse(rowStr) ?? 1;
        }
        rowMap.putIfAbsent(rowIndex, () => []).add(p);
      }
      final sortedKeys = rowMap.keys.toList()..sort();
      return sortedKeys.map((k) => rowMap[k]!).toList();
    }

    // Fallback using formation string e.g. "4-3-3" or "4-2-3-1"
    List<int> lineCounts = [1]; // Goalkeeper
    final parts = lineup.formation.split(RegExp(r'[-–]'));
    for (var part in parts) {
      final count = int.tryParse(part.trim());
      if (count != null && count > 0) {
        lineCounts.add(count);
      }
    }

    if (lineCounts.isEmpty) {
      lineCounts = [1, 4, 3, 3];
    } else {
      final totalExpected = lineCounts.fold<int>(0, (a, b) => a + b);
      if (totalExpected != players.length && players.length == 11) {
        lineCounts = [1, 4, 3, 3];
      }
    }

    final List<List<Player>> organized = [];
    int playerIndex = 0;
    for (var count in lineCounts) {
      final List<Player> row = [];
      for (int i = 0; i < count && playerIndex < players.length; i++) {
        row.add(players[playerIndex]);
        playerIndex++;
      }
      if (row.isNotEmpty) {
        organized.add(row);
      }
    }
    // Any remaining players
    if (playerIndex < players.length) {
      if (organized.isNotEmpty) {
        organized.last.addAll(players.sublist(playerIndex));
      } else {
        organized.add(players.sublist(playerIndex));
      }
    }

    return organized;
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Grass stripes (alternating)
    final stripePaint = Paint()
      ..color = const Color(0xFF164427)
      ..style = PaintingStyle.fill;
    const stripeCount = 6;
    final stripeHeight = size.height / stripeCount;
    for (int i = 0; i < stripeCount; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight),
        stripePaint,
      );
    }

    // Touchlines
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Halfway line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Center circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.15,
      paint,
    );

    // Center spot
    final spotPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      3,
      spotPaint,
    );

    // Top penalty area
    final boxWidth = size.width * 0.55;
    final boxHeight = size.height * 0.16;
    canvas.drawRect(
      Rect.fromLTWH((size.width - boxWidth) / 2, 0, boxWidth, boxHeight),
      paint,
    );

    // Bottom penalty area
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - boxWidth) / 2,
        size.height - boxHeight,
        boxWidth,
        boxHeight,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
