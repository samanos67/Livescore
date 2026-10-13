import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local/favorites_service.dart';
import '../onboarding/onboarding_screen.dart';
import 'privacy_policy_screen.dart';
import '../live_tv/live_tv_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = _favoritesService.areNotificationsEnabled();
  }

  Future<void> _rateApp() async {
    final uri    = Uri.parse('market://details?id=com.asdevelopments.livescore.livescore');
    final webUri = Uri.parse('https://play.google.com/store/apps/details?id=com.asdevelopments.livescore.livescore');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 28,
                height: 28,
              ),
            ),
            const SizedBox(width: 10),
            const Text('More', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: ListView(
        children: [
          // ── App Brand Card ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            alignment: Alignment.center,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'LiveScore Pro',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                const Text(
                  'v1.0.0 · Real-time Scores, News & Streams',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          _buildSectionHeader('Preferences & Clubs'),
          ListTile(
            leading: const Icon(Icons.favorite, color: AppColors.primary),
            title: const Text('Manage Followed Clubs'),
            subtitle: const Text('Add or remove your favourite clubs'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OnboardingScreen(isInitialLaunch: false)),
            ),
          ),

          _buildSectionHeader('Watch'),
          ListTile(
            leading: const Icon(Icons.live_tv, color: AppColors.primary),
            title: const Text('Live TV & Match Streams'),
            subtitle: const Text('Watch live matches and official broadcasts'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LiveTvScreen()),
            ),
          ),

          _buildSectionHeader('Settings'),
          SwitchListTile(
            title: const Text('Match Notifications'),
            subtitle: const Text('Kickoff reminders & live score updates'),
            value: _notificationsEnabled,
            activeColor: AppColors.primary,
            onChanged: (val) async {
              setState(() => _notificationsEnabled = val);
              final messenger = ScaffoldMessenger.of(context);
              await _favoritesService.setNotificationsEnabled(val);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(val ? 'Match notifications enabled' : 'Match notifications muted'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppColors.secondary,
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Theme'),
            subtitle: const Text('Dark Mode (Default)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: const Text('English'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),

          _buildSectionHeader('Support'),
          ListTile(
            title: const Text('Rate App'),
            subtitle: const Text('Enjoying the app? Rate us on Google Play'),
            trailing: const Icon(Icons.star, color: Colors.amber),
            onTap: _rateApp,
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          ListTile(
            title: const Text('About LiveScore Pro'),
            subtitle: const Text('Version 1.0.0'),
            trailing: const Icon(Icons.info_outline),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'LiveScore Pro',
                applicationVersion: '1.0.0',
                applicationIcon: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/app_logo.png', width: 48, height: 48),
                ),
                children: [
                  const Text('Your ultimate football companion for live scores, fixtures, lineups, statistics, and streaming guides.'),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.secondary,
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
      ),
    );
  }
}
