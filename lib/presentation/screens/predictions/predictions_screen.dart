import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/prediction_provider.dart';
import 'prediction_card_widget.dart';
import '../../widgets/banner_ad_widget.dart';

class PredictionsScreen extends ConsumerWidget {
  const PredictionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionsAsync = ref.watch(todayPredictionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1319),
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_rounded, color: Color(0xFF00D084), size: 22),
            SizedBox(width: 8),
            Text(
              'AI Match Forecasts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B202A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00D084)),
            tooltip: 'Refresh Forecasts',
            onPressed: () {
              ref.invalidate(todayPredictionsProvider);
            },
          ),
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(),
      body: RefreshIndicator(
        color: const Color(0xFF00D084),
        onRefresh: () async {
          ref.invalidate(todayPredictionsProvider);
        },
        child: predictionsAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF00D084)),
                SizedBox(height: 16),
                Text(
                  'Computing statistical signals & AI forecasts...',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 54, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text(
                    'Unable to Load AI Predictions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(todayPredictionsProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D084),
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (predictions) {
            if (predictions.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_busy, size: 54, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        'No Match Forecasts Scheduled',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Upcoming fixtures will be analyzed automatically when fixtures are scheduled.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              itemCount: predictions.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildHeroBanner(predictions.length);
                }
                final p = predictions[index - 1];
                return PredictionCardWidget(
                  prediction: p,
                  fixtureId: p.fixtureId,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroBanner(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D084).withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D084),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'TODAY’S HIGHLIGHTS',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$count Forecasts Ready',
                style: const TextStyle(
                  color: Color(0xFF00D084),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Objective Match Signals & Tactical Models',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Powered by expected goals (xG), recent team form, and Google Gemini AI. Sorted by model confidence.',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
