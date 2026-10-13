import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/fixture.dart';
import '../../domain/entities/match_event.dart';

enum PitchActionType {
  possession,
  attack,
  dangerousAttack,
  cornerKick,
  freeKick,
  penalty,
  goal,
  shotOnTarget,
  yellowCard,
  substitution,
}

class LivePitchTrackerWidget extends StatefulWidget {
  final Fixture fixture;
  final List<MatchEvent> events;

  const LivePitchTrackerWidget({
    super.key,
    required this.fixture,
    this.events = const [],
  });

  @override
  State<LivePitchTrackerWidget> createState() => _LivePitchTrackerWidgetState();
}

class _LivePitchTrackerWidgetState extends State<LivePitchTrackerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _simulationTimer;

  PitchActionType _currentAction = PitchActionType.possession;
  bool _isHomeAttacking = true;
  String _actionText = 'Live in Play';
  String _actionDetail = 'Tracking match in real-time';
  int _selectedEventIndex = -1; // -1 means following live match

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _syncLiveMatchState();
    _startLiveSyncTimer();
  }

  @override
  void didUpdateWidget(covariant LivePitchTrackerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fixture.elapsed != widget.fixture.elapsed ||
        oldWidget.events.length != widget.events.length ||
        oldWidget.fixture.statusShort != widget.fixture.statusShort) {
      _syncLiveMatchState();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _startLiveSyncTimer() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      if (_selectedEventIndex == -1) {
        _syncLiveMatchState();
      }
    });
  }

  void _syncLiveMatchState() {
    if (!mounted) return;
    if (_selectedEventIndex != -1) return; // User is viewing an explicit event

    final status = widget.fixture.statusShort.toUpperCase();

    // 1. Half-Time Break
    if (status == 'HT') {
      setState(() {
        _currentAction = PitchActionType.possession;
        _actionText = 'HALF TIME (HT)';
        _actionDetail = 'Break in play. Teams in dressing room.';
        _isHomeAttacking = true;
      });
      return;
    }

    // 2. Full-Time or Finished
    if (widget.fixture.isFinished || status == 'FT' || status == 'AET' || status == 'PEN') {
      setState(() {
        _currentAction = PitchActionType.possession;
        _actionText = 'FULL TIME (${widget.fixture.goalsHome ?? 0}-${widget.fixture.goalsAway ?? 0})';
        _actionDetail = 'Match completed.';
        _isHomeAttacking = true;
      });
      return;
    }

    // 3. Not Started / Upcoming
    if (status == 'NS' || status == 'TBD') {
      setState(() {
        _currentAction = PitchActionType.possession;
        _actionText = 'PRE-MATCH';
        _actionDetail = 'Match has not started yet. Radar activates at kick-off.';
        _isHomeAttacking = true;
      });
      return;
    }

    // 4. Live Match in Play (1H, 2H, ET, etc.)
    // Inspect actual real-time events that occurred
    if (widget.events.isNotEmpty) {
      final sorted = List<MatchEvent>.from(widget.events)
        ..sort((a, b) => a.elapsed.compareTo(b.elapsed));
      final latest = sorted.last;
      final currentElapsed = widget.fixture.elapsed ?? latest.elapsed;
      final isRecent = (currentElapsed - latest.elapsed).abs() <= 5;

      if (isRecent) {
        final isHome = latest.teamId == widget.fixture.homeTeam.id;
        final teamName = isHome ? widget.fixture.homeTeam.name : widget.fixture.awayTeam.name;

        setState(() {
          _isHomeAttacking = isHome;
          if (latest.isGoal) {
            _currentAction = latest.detail.toLowerCase().contains('pen')
                ? PitchActionType.penalty
                : PitchActionType.goal;
            _actionText = "GOAL! (${latest.elapsed}')";
            _actionDetail = "${latest.playerName} scores for $teamName!";
          } else if (latest.isYellowCard || latest.isRedCard) {
            _currentAction = PitchActionType.yellowCard;
            _actionText = "${latest.isRedCard ? 'RED CARD' : 'BOOKING'} (${latest.elapsed}')";
            _actionDetail = "${latest.playerName} ($teamName) booked";
          } else if (latest.isSub) {
            _currentAction = PitchActionType.substitution;
            _actionText = "SUBSTITUTION (${latest.elapsed}')";
            _actionDetail = "${latest.playerName} brought on for $teamName";
          } else {
            _currentAction = PitchActionType.dangerousAttack;
            _actionText = "${latest.elapsed}' INCIDENT";
            _actionDetail = "${latest.playerName}: ${latest.detail}";
          }
        });
        return;
      }
    }

    // 5. Active Live Game Open Play
    final elapsedMin = widget.fixture.elapsed ?? 1;
    setState(() {
      _currentAction = PitchActionType.possession;
      _actionText = "$elapsedMin' LIVE IN PLAY";
      _actionDetail = "${widget.fixture.homeTeam.name} ${widget.fixture.goalsHome ?? 0} - ${widget.fixture.goalsAway ?? 0} ${widget.fixture.awayTeam.name}";
      _isHomeAttacking = ((elapsedMin ~/ 2) % 2 == 0);
    });
  }

  void _selectEvent(int index) {
    if (index < 0 || index >= widget.events.length) {
      setState(() {
        _selectedEventIndex = -1;
      });
      _syncLiveMatchState();
      return;
    }

    final event = widget.events[index];
    final isHome = event.teamId == widget.fixture.homeTeam.id;

    setState(() {
      _selectedEventIndex = index;
      _isHomeAttacking = isHome;

      if (event.isGoal) {
        if (event.detail.toLowerCase().contains('pen')) {
          _currentAction = PitchActionType.penalty;
          _actionText = "PENALTY GOAL! (${event.elapsed}')";
          _actionDetail = '${event.playerName} converts from the spot!';
        } else {
          _currentAction = PitchActionType.goal;
          _actionText = "GOAL! (${event.elapsed}')";
          _actionDetail = '${event.playerName} finds the back of the net!';
        }
      } else if (event.isYellowCard || event.isRedCard) {
        _currentAction = PitchActionType.yellowCard;
        _actionText = event.isRedCard ? "RED CARD (${event.elapsed}')" : "BOOKING (${event.elapsed}')";
        _actionDetail = '${event.playerName} shown card for a challenge';
      } else if (event.isSub) {
        _currentAction = PitchActionType.substitution;
        _actionText = "SUBSTITUTION (${event.elapsed}')";
        _actionDetail = '${event.playerName} enters the pitch';
      } else {
        _currentAction = PitchActionType.dangerousAttack;
        _actionText = "INCIDENT (${event.elapsed}')";
        _actionDetail = '${event.playerName}: ${event.detail}';
      }
    });
  }

  Color _getActionColor() {
    switch (_currentAction) {
      case PitchActionType.goal:
      case PitchActionType.penalty:
        return const Color(0xFF00E676); // Vibrant Green
      case PitchActionType.dangerousAttack:
      case PitchActionType.shotOnTarget:
        return const Color(0xFFFF5252); // Red Alert
      case PitchActionType.cornerKick:
      case PitchActionType.freeKick:
        return const Color(0xFFFFD700); // Gold
      case PitchActionType.yellowCard:
        return Colors.amber;
      case PitchActionType.attack:
        return const Color(0xFFFF9100); // Orange
      case PitchActionType.possession:
      case PitchActionType.substitution:
      default:
        return const Color(0xFF40C4FF); // Cyan
    }
  }

  @override
  Widget build(BuildContext context) {
    final attackingTeam = _isHomeAttacking ? widget.fixture.homeTeam : widget.fixture.awayTeam;
    final actionColor = _getActionColor();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141824),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: Live Incident Bar ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFF0F121C),
            child: Row(
              children: [
                // Animated Blinking Live Dot
                AnimatedBuilder(
                  animation: _animController,
                  builder: (_, __) {
                    final pulse = (_animController.value * 2 * math.pi);
                    final opacity = 0.5 + 0.5 * math.sin(pulse);
                    return Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: actionColor.withOpacity(opacity),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: actionColor.withOpacity(0.6),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),

                // Attacking team crest
                if (attackingTeam.logoUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: attackingTeam.logoUrl,
                      width: 18,
                      height: 18,
                      errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 18, color: Colors.white54),
                    ),
                  ),
                const SizedBox(width: 6),

                // Team name
                Expanded(
                  child: Text(
                    attackingTeam.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                // Action Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: actionColor.withOpacity(0.6)),
                  ),
                  child: Text(
                    _actionText.toUpperCase(),
                    style: TextStyle(
                      color: actionColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Match minute
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.fixture.isLive ? "${widget.fixture.elapsed ?? 45}'" : (widget.fixture.isFinished ? 'FT' : 'LIVE'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 2D Pitch Canvas ──────────────────────────────────────────────────
          SizedBox(
            height: 200,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(double.infinity, 200),
                  painter: _PitchTrackerPainter(
                    animValue: _animController.value,
                    action: _currentAction,
                    isHomeAttacking: _isHomeAttacking,
                    actionColor: actionColor,
                  ),
                );
              },
            ),
          ),

          // ── Commentary / Action Detail Line ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFF0F121C),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.radar, size: 14, color: actionColor),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _actionDetail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'LIVE TRACKER',
                  style: TextStyle(
                    color: actionColor.withOpacity(0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // ── Match Events Replay Scrubber (Goals & Incidents) ─────────────────
          if (widget.events.isNotEmpty) ...[
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: const Color(0xFF0A0D14),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Live Now Mode Pill
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sensors, size: 11, color: _selectedEventIndex == -1 ? Colors.black : AppColors.primary),
                          const SizedBox(width: 4),
                          const Text('LIVE NOW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      selected: _selectedEventIndex == -1,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white12,
                      labelStyle: TextStyle(
                        color: _selectedEventIndex == -1 ? Colors.black : Colors.white,
                      ),
                      onSelected: (_) => _selectEvent(-1),
                    ),
                  ),

                  // Event Pills (Goals, Cards, Substitutions)
                  ...List.generate(widget.events.length, (idx) {
                    final ev = widget.events[idx];
                    final isSelected = _selectedEventIndex == idx;
                    final isGoal = ev.isGoal;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                      child: ChoiceChip(
                        label: Text(
                          '${isGoal ? "⚽" : (ev.isYellowCard ? "🟨" : (ev.isRedCard ? "🟥" : "🔄"))} ${ev.elapsed}\' ${ev.playerName.split(" ").last}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.black : Colors.white70,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: isGoal ? const Color(0xFF00E676) : Colors.amber,
                        backgroundColor: Colors.white10,
                        onSelected: (_) => _selectEvent(idx),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PitchTrackerPainter extends CustomPainter {
  final double animValue;
  final PitchActionType action;
  final bool isHomeAttacking;
  final Color actionColor;

  _PitchTrackerPainter({
    required this.animValue,
    required this.action,
    required this.isHomeAttacking,
    required this.actionColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw Pitch Turf Grass Stripes
    const grassDark = Color(0xFF13361F);
    const grassLight = Color(0xFF194628);
    const stripeCount = 10;
    final stripeWidth = w / stripeCount;

    for (int i = 0; i < stripeCount; i++) {
      final paint = Paint()..color = (i % 2 == 0) ? grassDark : grassLight;
      canvas.drawRect(Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, h), paint);
    }

    // Vignette shadow around pitch edges
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), vignette);

    // 2. White Pitch Boundary Lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Outer touchline with padding
    const p = 8.0;
    final pitchRect = Rect.fromLTWH(p, p, w - 2 * p, h - 2 * p);
    canvas.drawRect(pitchRect, linePaint);

    // Halfway line
    canvas.drawLine(Offset(w / 2, p), Offset(w / 2, h - p), linePaint);

    // Center circle
    final centerCircleRadius = h * 0.22;
    canvas.drawCircle(Offset(w / 2, h / 2), centerCircleRadius, linePaint);

    // Center spot
    final spotPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), 3, spotPaint);

    // Left Penalty Box (Home goal area)
    final boxW = w * 0.16;
    final boxH = h * 0.58;
    final boxTop = (h - boxH) / 2;
    canvas.drawRect(Rect.fromLTWH(p, boxTop, boxW, boxH), linePaint);

    // Left 6-yard box
    final sixW = w * 0.06;
    final sixH = h * 0.32;
    canvas.drawRect(Rect.fromLTWH(p, (h - sixH) / 2, sixW, sixH), linePaint);

    // Left Penalty spot
    canvas.drawCircle(Offset(p + boxW * 0.75, h / 2), 2.5, spotPaint);

    // Right Penalty Box (Away goal area)
    canvas.drawRect(Rect.fromLTWH(w - p - boxW, boxTop, boxW, boxH), linePaint);

    // Right 6-yard box
    canvas.drawRect(Rect.fromLTWH(w - p - sixW, (h - sixH) / 2, sixW, sixH), linePaint);

    // Right Penalty spot
    canvas.drawCircle(Offset(w - p - boxW * 0.75, h / 2), 2.5, spotPaint);

    // Corner arcs
    canvas.drawArc(Rect.fromCircle(center: const Offset(p, p), radius: 8), 0, math.pi / 2, false, linePaint);
    canvas.drawArc(Rect.fromCircle(center: Offset(p, h - p), radius: 8), -math.pi / 2, math.pi / 2, false, linePaint);
    canvas.drawArc(Rect.fromCircle(center: Offset(w - p, p), radius: 8), math.pi / 2, math.pi / 2, false, linePaint);
    canvas.drawArc(Rect.fromCircle(center: Offset(w - p, h - p), radius: 8), math.pi, math.pi / 2, false, linePaint);

    // 3. Dynamic Attack Wave / Radar Cones
    _drawAttackWave(canvas, size);

    // 4. Ball Position, Glow & Trajectory
    _drawBallAndAction(canvas, size);
  }

  void _drawAttackWave(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Attacking direction: Home attacks Left -> Right, Away attacks Right -> Left
    final startX = isHomeAttacking ? w * 0.35 : w * 0.65;
    final targetX = isHomeAttacking ? w * 0.88 : w * 0.12;

    // Dynamic wave progression based on animValue
    final waveAlpha = 0.2 + 0.15 * math.sin(animValue * 2 * math.pi);
    final waveColor = actionColor.withOpacity(waveAlpha);

    final path = Path();
    if (isHomeAttacking) {
      path.moveTo(startX, h * 0.25);
      path.lineTo(targetX, h * 0.12);
      path.lineTo(targetX, h * 0.88);
      path.lineTo(startX, h * 0.75);
    } else {
      path.moveTo(startX, h * 0.25);
      path.lineTo(targetX, h * 0.12);
      path.lineTo(targetX, h * 0.88);
      path.lineTo(startX, h * 0.75);
    }
    path.close();

    final sweepGradient = Paint()
      ..shader = LinearGradient(
        begin: isHomeAttacking ? Alignment.centerLeft : Alignment.centerRight,
        end: isHomeAttacking ? Alignment.centerRight : Alignment.centerLeft,
        colors: [
          waveColor.withOpacity(0.0),
          waveColor,
          waveColor.withOpacity(0.35),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(path, sweepGradient);

    // Animated chevron arrows showing attacking momentum
    const arrowCount = 3;
    for (int i = 0; i < arrowCount; i++) {
      final t = (animValue + i / arrowCount) % 1.0;
      final arrowX = isHomeAttacking
          ? startX + (targetX - startX) * t
          : startX - (startX - targetX) * t;

      final arrowPaint = Paint()
        ..color = actionColor.withOpacity(0.6 * (1.0 - t))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      final arrowPath = Path();
      if (isHomeAttacking) {
        arrowPath.moveTo(arrowX - 8, h / 2 - 12);
        arrowPath.lineTo(arrowX + 4, h / 2);
        arrowPath.lineTo(arrowX - 8, h / 2 + 12);
      } else {
        arrowPath.moveTo(arrowX + 8, h / 2 - 12);
        arrowPath.lineTo(arrowX - 4, h / 2);
        arrowPath.lineTo(arrowX + 8, h / 2 + 12);
      }
      canvas.drawPath(arrowPath, arrowPaint);
    }
  }

  void _drawBallAndAction(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Calculate ball position according to the active action
    double ballX;
    double ballY;
    double targetX = isHomeAttacking ? w * 0.88 : w * 0.12;
    double targetY = h / 2;

    switch (action) {
      case PitchActionType.possession:
        ballX = isHomeAttacking ? w * 0.42 + 20 * math.sin(animValue * math.pi) : w * 0.58 - 20 * math.sin(animValue * math.pi);
        ballY = h / 2 + 25 * math.cos(animValue * math.pi);
        break;

      case PitchActionType.attack:
        ballX = isHomeAttacking ? w * 0.65 + 15 * math.sin(animValue * 2 * math.pi) : w * 0.35 - 15 * math.sin(animValue * 2 * math.pi);
        ballY = h * 0.35 + 20 * math.sin(animValue * math.pi);
        break;

      case PitchActionType.dangerousAttack:
      case PitchActionType.shotOnTarget:
        final t = (animValue * 1.5).clamp(0.0, 1.0);
        final startX = isHomeAttacking ? w * 0.68 : w * 0.32;
        final startY = h * 0.4;
        ballX = startX + (targetX - startX) * t;
        ballY = startY + (targetY - startY) * t;

        // Draw shot trajectory dash line
        final trajPaint = Paint()
          ..color = actionColor.withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawLine(Offset(startX, startY), Offset(ballX, ballY), trajPaint);
        break;

      case PitchActionType.cornerKick:
        final cornerX = isHomeAttacking ? w - 10 : 10;
        final cornerY = (h < 150) ? 12.0 : 14.0;
        final t = (animValue).clamp(0.0, 1.0);
        ballX = cornerX + (targetX - cornerX) * t;
        ballY = cornerY + (h / 2 - cornerY) * t;

        // Curved arc path from corner
        final arcPath = Path();
        arcPath.moveTo(cornerX.toDouble(), cornerY);
        arcPath.quadraticBezierTo(isHomeAttacking ? w * 0.85 : w * 0.15, h * 0.25, ballX, ballY);
        final arcPaint = Paint()
          ..color = Colors.amber.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawPath(arcPath, arcPaint);
        break;

      case PitchActionType.penalty:
        final spotX = isHomeAttacking ? w - 8 - (w * 0.16 * 0.75) : 8 + (w * 0.16 * 0.75);
        final spotY = h / 2;
        final goalX = isHomeAttacking ? w - 8 : 8;
        final t = animValue.clamp(0.0, 1.0);
        ballX = spotX + (goalX - spotX) * t;
        ballY = spotY;
        break;

      case PitchActionType.goal:
        ballX = isHomeAttacking ? w - 12 : 12;
        ballY = h / 2 + 10 * math.sin(animValue * 4 * math.pi);

        // Goal explosion burst rings
        final burstPaint = Paint()
          ..color = const Color(0xFF00E676).withOpacity((1.0 - animValue).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(Offset(ballX, h / 2), 15 + animValue * 35, burstPaint);
        break;

      default:
        ballX = isHomeAttacking ? w * 0.6 : w * 0.4;
        ballY = h / 2;
        break;
    }

    // Glowing Target Ring under Ball
    final targetRing = Paint()
      ..color = actionColor.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(ballX, ballY), 12 + 4 * math.sin(animValue * 2 * math.pi), targetRing);

    // Outer Ball Glow
    final ballGlow = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(ballX, ballY), 6, ballGlow);

    // Ball Core (White with dark border)
    final ballCore = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(ballX, ballY), 5, ballCore);

    final ballBorder = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(ballX, ballY), 5, ballBorder);
  }

  @override
  bool shouldRepaint(covariant _PitchTrackerPainter oldDelegate) {
    return oldDelegate.animValue != animValue ||
        oldDelegate.action != action ||
        oldDelegate.isHomeAttacking != isHomeAttacking;
  }
}
