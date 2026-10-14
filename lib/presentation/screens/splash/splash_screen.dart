import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local/favorites_service.dart';
import '../main_screen.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for splash duration
    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;

    final favService = FavoritesService();
    final hasCompletedOnboarding = favService.hasCompletedOnboarding();
    final favoriteTeams = favService.getFavoriteTeams();
    final shouldShowOnboarding = !hasCompletedOnboarding || favoriteTeams.isEmpty;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: shouldShowOnboarding
              ? const OnboardingScreen(isInitialLaunch: true)
              : const MainScreen(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Subtle radial background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    AppColors.primary.withOpacity(0.08),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),

          // Center Logo and Brand
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing App Icon
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(44),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // App Title
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'LiveScore ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'PRO',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tagline
                    const Text(
                      'Live Scores • Real-Time Stats • Streams',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Loading / Version indicator
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Column(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary.withOpacity(0.7)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: Colors.grey.withOpacity(0.6),
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
