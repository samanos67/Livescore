import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Introduction',
              'LiveScore ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and share information when you use our mobile application.',
            ),
            _buildSection(
              '1. Information We Collect',
              'We collect the following types of information:\n\n'
              '• Device Information: We collect information about your device, including device model, operating system, and unique device identifiers.\n\n'
              '• Usage Data: We collect information about how you use the app, including features accessed and time spent.\n\n'
              '• Preferences: We store your favorite teams and notification preferences locally on your device.',
            ),
            _buildSection(
              '2. How We Use Your Information',
              'We use the collected information to:\n\n'
              '• Provide and improve our services\n'
              '• Personalize your experience\n'
              '• Send you notifications about matches and scores\n'
              '• Display relevant advertisements\n'
              '• Analyze app usage and performance',
            ),
            _buildSection(
              '3. Third-Party Services',
              'We use third-party services that may collect information:\n\n'
              '• Google AdMob: For displaying advertisements\n'
              '• Firebase: For push notifications and analytics\n'
              '• API-Football: For match data and statistics\n'
              '• YouTube: For video highlights',
            ),
            _buildSection(
              '4. Data Storage',
              'Your favorite teams and preferences are stored locally on your device using Hive database. We do not store this information on our servers.',
            ),
            _buildSection(
              '5. Advertisements',
              'We display advertisements through Google AdMob. AdMob may collect and use information about you to provide personalized ads. You can learn more about how Google uses data at: https://policies.google.com/privacy',
            ),
            _buildSection(
              '6. Children\'s Privacy',
              'Our app is not intended for children under 13. We do not knowingly collect personal information from children under 13.',
            ),
            _buildSection(
              '7. Your Rights',
              'You have the right to:\n\n'
              '• Access your data\n'
              '• Delete your data (favorites and preferences)\n'
              '• Opt-out of personalized advertisements\n'
              '• Disable push notifications',
            ),
            _buildSection(
              '8. Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy in the app.',
            ),
            _buildSection(
              '9. Contact Us',
              'If you have any questions about this Privacy Policy, please contact us at:\n\n'
              'Email: support@livescoreapp.com',
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Last Updated: ${DateTime.now().year}-02-07',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
