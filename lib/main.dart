import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/main_screen.dart';
import 'data/datasources/local/favorites_service.dart';
import 'services/notification_service.dart';
import 'services/admob_service.dart';
import 'services/interstitial_ad_service.dart';
import 'services/app_open_ad_service.dart';

// Global ad services
final interstitialAdService = InterstitialAdService();
final appOpenAdService = AppOpenAdService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FavoritesService().init();
  await NotificationService().init();
  await AdMobService().init();
  
  // Load ads
  interstitialAdService.loadAd();
  appOpenAdService.loadAd();
  
  runApp(const ProviderScope(child: LiveScoreApp()));
}

class LiveScoreApp extends StatelessWidget {
  const LiveScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiveScore',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to dark mode
      home: const MainScreen(),
    );
  }
}
