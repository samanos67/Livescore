import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import 'privacy_policy_screen.dart';
import '../live_tv/live_tv_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

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
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          _buildSectionHeader('Watch'),
          ListTile(
            leading: const Icon(Icons.live_tv, color: AppColors.primary),
            title: const Text('Live TV & Match Streams'),
            subtitle: const Text('Watch live matches'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LiveTvScreen()),
            ),
          ),
          _buildSectionHeader('Settings'),
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Enable push notifications'),
            value: true,
            activeColor: AppColors.primary,
            onChanged: (val) {},
          ),
          ListTile(
            title: const Text('Theme'),
            subtitle: const Text('Dark Mode'),
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
            subtitle: const Text('Enjoying the app? Rate us!'),
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
            title: const Text('About'),
            subtitle: const Text('Version 1.0.0'),
            trailing: const Icon(Icons.info_outline),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'LiveScore',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.sports_soccer, size: 48, color: AppColors.primary),
                children: [
                  const Text('Your ultimate football companion for live scores, fixtures, and highlights.'),
                ],
              );
            },
          ),
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
