import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/match_prediction.dart';
import '../../providers/prediction_provider.dart';
import '../../../services/rewarded_ad_service.dart';

class PredictionCardWidget extends ConsumerStatefulWidget {
  final MatchPrediction prediction;
  final int fixtureId;

  const PredictionCardWidget({
    super.key,
    required this.prediction,
    required this.fixtureId,
  });

  @override
  ConsumerState<PredictionCardWidget> createState() => _PredictionCardWidgetState();
}

class _PredictionCardWidgetState extends ConsumerState<PredictionCardWidget> {
  late final RewardedAdService _rewardedAdService;
  bool _isLoadingAd = false;

  @override
  void initState() {
    super.initState();
    _rewardedAdService = RewardedAdService();
    _rewardedAdService.loadRewardedAd();
  }

  @override
  void dispose() {
    _rewardedAdService.dispose();
    super.dispose();
  }

  void _unlockFullAnalysis() {
    setState(() => _isLoadingAd = true);

    _rewardedAdService.showRewardedAd(
      onRewardEarned: () {
        ref.read(unlockedPredictionsProvider.notifier).update((state) {
          final newState = Set<int>.from(state);
          newState.add(widget.fixtureId);
          return newState;
        });

        if (mounted) {
          setState(() => _isLoadingAd = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⭐ Full AI Tactical Analysis Unlocked!'),
              backgroundColor: Color(0xFF00D084),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      onAdDismissed: () {
        if (mounted) {
          setState(() => _isLoadingAd = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final unlockedSet = ref.watch(unlockedPredictionsProvider);
    final isUnlocked = unlockedSet.contains(widget.fixtureId);
    final p = widget.prediction;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B202A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D084).withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D084).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Header ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF242B38),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D084).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: Color(0xFF00D084),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'AI MATCH FORECAST',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D084).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00D084).withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${p.confidence}% Confidence',
                    style: const TextStyle(
                      color: Color(0xFF00D084),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Scoreline Forecast ────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Text(
                        p.homeTeam,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1319),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00D084).withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        p.predictedScoreString,
                        style: const TextStyle(
                          color: Color(0xFF00D084),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        p.awayTeam,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Expected Goals (xG): ${p.homeTeam} ${p.homeXg.toStringAsFixed(2)}  •  ${p.awayTeam} ${p.awayXg.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ─── Probability Bar ──────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      children: [
                        Flexible(
                          flex: p.homeWinProb,
                          child: Container(color: const Color(0xFF00D084)),
                        ),
                        Flexible(
                          flex: p.drawProb,
                          child: Container(color: const Color(0xFFF59E0B)),
                        ),
                        Flexible(
                          flex: p.awayWinProb,
                          child: Container(color: const Color(0xFF3B82F6)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Probability Labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildProbLabel(
                      '${p.homeTeam} Win',
                      '${p.homeWinProb}%',
                      const Color(0xFF00D084),
                    ),
                    _buildProbLabel(
                      'Draw',
                      '${p.drawProb}%',
                      const Color(0xFFF59E0B),
                    ),
                    _buildProbLabel(
                      '${p.awayTeam} Win',
                      '${p.awayWinProb}%',
                      const Color(0xFF3B82F6),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFF2C3444), height: 1),
                const SizedBox(height: 14),

                // ─── Key Factors ──────────────────────────────────
                const Row(
                  children: [
                    Icon(Icons.analytics_outlined, color: Colors.white70, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Key Signals',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Always show first factor in free tier
                if (p.keyFactors.isNotEmpty)
                  _buildFactorRow(p.keyFactors.first),

                // Additional factors if unlocked
                if (isUnlocked) ...[
                  for (int i = 1; i < p.keyFactors.length; i++)
                    _buildFactorRow(p.keyFactors[i]),
                  
                  const SizedBox(height: 14),
                  
                  // Tactical Insight
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131720),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF00D084).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.psychology, color: Color(0xFF00D084), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Tactical Breakdown',
                              style: TextStyle(
                                color: Color(0xFF00D084),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.tacticalInsight,
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Stat Badges (BTTS & Over 2.5)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildChip(
                        label: 'Both Teams Score: ${p.btts ? "Yes" : "No"}',
                        icon: Icons.sports_soccer,
                        color: p.btts ? const Color(0xFF00D084) : Colors.grey,
                      ),
                      _buildChip(
                        label: 'Over 2.5 Goals: ${p.over25Goals ? "Yes" : "No"}',
                        icon: Icons.trending_up,
                        color: p.over25Goals ? const Color(0xFF00D084) : Colors.grey,
                      ),
                      _buildChip(
                        label: p.model.contains('gemini') ? 'Gemini AI Verified' : 'Statistical Model',
                        icon: Icons.verified,
                        color: const Color(0xFF3B82F6),
                      ),
                    ],
                  ),
                ] else ...[
                  // ─── Locked State (Rewarded Ad CTA) ───────────────
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131720),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lock_outline, color: Colors.amber, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Full AI Tactical Analysis & Additional Signals',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Unlock detailed match tactics, expected goals analysis, both-teams-to-score probabilities, and key duels.',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _isLoadingAd ? null : _unlockFullAnalysis,
                          icon: _isLoadingAd
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.play_circle_fill, size: 18),
                          label: Text(
                            _isLoadingAd ? 'Loading Video...' : 'Watch Video to Unlock (Free)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D084),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // ─── Disclaimer ───────────────────────────────────
                Text(
                  p.disclaimer,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProbLabel(String title, String percent, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$title: ',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
        ),
        Text(
          percent,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFactorRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: Color(0xFF00D084),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
