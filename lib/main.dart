import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local/favorites_service.dart';
import 'services/notification_service.dart';
import 'services/admob_service.dart';
import 'services/interstitial_ad_service.dart';
import 'services/rewarded_ad_service.dart';

import 'presentation/screens/splash/splash_screen.dart';

// Global ad services
final interstitialAdService = InterstitialAdService();
final rewardedAdService = RewardedAdService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final favService = FavoritesService();
  await favService.init();
  await NotificationService().init();
  await AdMobService().init();
  
  // Preload ads
  interstitialAdService.loadAd();
  rewardedAdService.loadRewardedAd();
  rewardedAdService.loadRewardedInterstitialAd();
  
  runApp(const ProviderScope(child: LiveScoreApp()));
}

class LiveScoreApp extends StatelessWidget {
  const LiveScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiveScore Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to dark mode
      home: const SplashScreen(),
    );
  }
}
