import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Acceptance of Terms',
              'Welcome to LiveScore Pro. By downloading, accessing, or using the LiveScore Pro mobile application ("the App"), provided by Asdevelopments LTD ("we", "our", or "us"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, please do not use the App.',
            ),
            _buildSection(
              '1. Nature of Service & Sports Data Disclaimer',
              'LiveScore Pro provides real-time football scores, match schedules, starting lineups, statistics, club news, and sports broadcasting information for personal, non-commercial entertainment and informational purposes only.\n\n'
              '• Live Latency: While we make every effort to deliver instantaneous live scores, transmission delays may occur depending on network conditions, data provider feeds, and device connectivity.\n\n'
              '• Accuracy Disclaimer: Match statistics, lineups, and fixtures are provided "as is". We do not guarantee 100% accuracy, completeness, or timeliness of data and shall not be held liable for any decisions made based on this information.\n\n'
              '• No Betting / Gambling Operations: LiveScore Pro does not offer, promote, or process real-money gambling or betting transactions.',
            ),
            _buildSection(
              '2. Live TV & Third-Party Streaming Links',
              'The App includes a Live TV guide and links to third-party streaming channels and official broadcasting schedules:\n\n'
              '• External Content: Third-party feeds, streams, and external links are hosted by independent operators. LiveScore Pro does not host, upload, or control third-party video streams.\n\n'
              '• Compliance with Local Laws: Users are solely responsible for ensuring their use of external links and broadcasts complies with applicable copyright and intellectual property laws in their jurisdiction.',
            ),
            _buildSection(
              '3. Intellectual Property & Trademarks',
              'All intellectual property rights in the App design, code, graphics, and features are owned by Asdevelopments LTD.\n\n'
              '• Fair Use & Nominative Reference: All team names, logos, competition names, and trademarks displayed in the App belong to their respective copyright and trademark holders. Their display in the App is strictly for identification, reference, and informational reporting purposes ("nominative fair use"). LiveScore Pro is not affiliated with, endorsed by, or sponsored by any football club, league, or federation unless explicitly stated.',
            ),
            _buildSection(
              '4. In-App Advertisements',
              'LiveScore Pro displays advertisements served via Google AdMob (including banner ads, interstitial ads, and voluntary rewarded ads) to support free access to our services. By using the App, you acknowledge and agree to the display of these advertisements in compliance with Google Play Policies.',
            ),
            _buildSection(
              '5. Push Notifications',
              'With your permission, LiveScore Pro may send push notifications for live goal alerts, match kickoffs, breaking football news, and transfer updates. You may enable, disable, or customize these notifications at any time via the App settings or your device system settings.',
            ),
            _buildSection(
              '6. User Conduct & Restrictions',
              'You agree not to:\n\n'
              '• Reverse engineer, decompile, or disassemble any part of the App.\n'
              '• Attempt to disrupt or circumvent the App infrastructure, API servers, or security features.\n'
              '• Use automated scrapers, bots, or scripts to extract data without written authorization.\n'
              '• Use the App for any unlawful, fraudulent, or harmful activity.',
            ),
            _buildSection(
              '7. Limitation of Liability',
              'To the maximum extent permitted by applicable law, Asdevelopments LTD, its officers, employees, and partners shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your access to or inability to use the App, including but not limited to loss of data, connectivity failures, or errors in match information.',
            ),
            _buildSection(
              '8. Modifications to Terms',
              'We reserve the right to modify or update these Terms of Service at any time. Any changes will become effective immediately upon posting in the App. Your continued use of the App following any updates signifies your acceptance of the revised Terms.',
            ),
            _buildSection(
              '9. Governing Law',
              'These Terms shall be governed by and construed in accordance with the laws of the United Kingdom, without regard to its conflict of law principles.',
            ),
            _buildSection(
              '10. Contact Us',
              'If you have questions, comments, or legal inquiries regarding these Terms of Service, please contact us at:\n\n'
              'Asdevelopments LTD\n'
              'Email: support@asdevelopments.com',
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Last Updated: November 2026',
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
              fontSize: 16,
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
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
