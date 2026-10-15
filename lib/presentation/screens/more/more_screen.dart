import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/datasources/local/favorites_service.dart';
import '../../../services/notification_service.dart';
import '../onboarding/onboarding_screen.dart';
import '../leagues/leagues_screen.dart';
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

  Future<void> _openTelegramChannel() async {
    final uri = Uri.parse(ApiConstants.telegramChannelUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening Telegram channel...')),
          );
        }
      }
    } catch (_) {}
  }

  void _triggerTestGoalAlert() async {
    await NotificationService().testSendGoalNotification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.sports_soccer, color: AppColors.primary, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Goal notification sent! Pull down your notification bar and tap it to test returning to the match.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.secondary,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _triggerTestNewsAlert() async {
    await NotificationService().testSendNewsNotification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.newspaper, color: AppColors.primary, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'News push notification sent! Tap it from your status bar to open the in-app article.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.secondary,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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

          // ── Football Hub ─────────────────────────────────────────────────
          _buildSectionHeader('Competitions & Broadcasts'),
          ListTile(
            leading: const Icon(Icons.emoji_events, color: AppColors.primary),
            title: const Text('Leagues & Standings'),
            subtitle: const Text('Premier League, Champions League, La Liga, Serie A'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaguesScreen()),
            ),
          ),
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
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF0088CC),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 16),
            ),
            title: const Text('Telegram Stream Channel'),
            subtitle: const Text('Join for live match links, goal clips & community'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0088CC).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF0088CC)),
              ),
              child: const Text(
                'JOIN',
                style: TextStyle(
                  color: Color(0xFF0088CC),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: _openTelegramChannel,
          ),

          // ── Club Preferences ─────────────────────────────────────────────
          _buildSectionHeader('Preferences & Clubs'),
          ListTile(
            leading: const Icon(Icons.favorite, color: AppColors.primary),
            title: const Text('Manage Followed Clubs'),
            subtitle: const Text('Add, remove or customize your favourite clubs'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OnboardingScreen(isInitialLaunch: false)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt, color: Colors.orangeAccent),
            title: const Text('Re-launch Club Picker'),
            subtitle: const Text('Test initial onboarding club selection flow'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OnboardingScreen(isInitialLaunch: true)),
            ),
          ),

          // ── Push Notification Testing & Settings ─────────────────────────
          _buildSectionHeader('Push Notifications'),
          SwitchListTile(
            title: const Text('Match & News Alerts'),
            subtitle: const Text('Instant goals, kickoff reminders & club news'),
            value: _notificationsEnabled,
            activeColor: AppColors.primary,
            onChanged: (val) async {
              setState(() => _notificationsEnabled = val);
              final messenger = ScaffoldMessenger.of(context);
              await _favoritesService.setNotificationsEnabled(val);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(val ? 'Notifications enabled' : 'Notifications muted'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppColors.secondary,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.sports_soccer, color: AppColors.primary),
            title: const Text('Test Instant Goal Push Notification'),
            subtitle: const Text('Sends a sample goal alert to lock screen & status bar'),
            trailing: const Icon(Icons.send, size: 18, color: AppColors.primary),
            onTap: _triggerTestGoalAlert,
          ),
          ListTile(
            leading: const Icon(Icons.newspaper, color: Colors.blueAccent),
            title: const Text('Test Breaking News Push Notification'),
            subtitle: const Text('Sends a breaking news alert with in-app deep link'),
            trailing: const Icon(Icons.send, size: 18, color: Colors.blueAccent),
            onTap: _triggerTestNewsAlert,
          ),

          // ── App Settings & Support ───────────────────────────────────────
          _buildSectionHeader('Support & Legal'),
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
            subtitle: const Text('Version 1.0.0 · Fast 4s Live Feeds'),
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
                  const Text('Your ultimate football companion for live scores, fixtures, lineups, statistics, breaking news and streaming guides.'),
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
