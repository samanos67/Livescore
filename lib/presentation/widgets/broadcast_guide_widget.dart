import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';

class BroadcasterInfo {
  final String name;
  final String region;
  final String regionCode; // 'UK', 'US', 'AF', 'ME', 'EU', 'GLOBAL'
  final String platform;
  final String coverage;
  final String url;
  final IconData icon;
  final Color brandColor;

  const BroadcasterInfo({
    required this.name,
    required this.region,
    required this.regionCode,
    required this.platform,
    required this.coverage,
    required this.url,
    required this.icon,
    required this.brandColor,
  });
}

class BroadcastGuideWidget extends StatefulWidget {
  final String matchTitle;

  const BroadcastGuideWidget({super.key, required this.matchTitle});

  @override
  State<BroadcastGuideWidget> createState() => _BroadcastGuideWidgetState();
}

class _BroadcastGuideWidgetState extends State<BroadcastGuideWidget> {
  String _selectedRegion = 'ALL';

  static const List<BroadcasterInfo> _broadcasters = [
    BroadcasterInfo(
      name: 'Sky Sports Premier League',
      region: 'United Kingdom & Ireland',
      regionCode: 'UK',
      platform: 'Sky Go / NOW TV',
      coverage: 'Live HD Broadcast & Commentary',
      url: 'https://www.skysports.com/watch',
      icon: Icons.tv,
      brandColor: Color(0xFF003865),
    ),
    BroadcasterInfo(
      name: 'TNT Sports (Discovery+)',
      region: 'United Kingdom & Ireland',
      regionCode: 'UK',
      platform: 'TNT Sports 1 & 2',
      coverage: 'UEFA Champions League & Premier League',
      url: 'https://www.discoveryplus.com/gb/sports',
      icon: Icons.sports_soccer,
      brandColor: Color(0xFFE50914),
    ),
    BroadcasterInfo(
      name: 'Peacock Premium',
      region: 'United States',
      regionCode: 'US',
      platform: 'NBC Sports Live Stream',
      coverage: 'All Premier League Matchdays Live',
      url: 'https://www.peacocktv.com/sports',
      icon: Icons.play_circle_filled,
      brandColor: Color(0xFF0058A3),
    ),
    BroadcasterInfo(
      name: 'Paramount+ / CBS Golazo',
      region: 'United States',
      regionCode: 'US',
      platform: 'CBS Sports Network',
      coverage: 'UEFA Champions League & Serie A',
      url: 'https://www.paramountplus.com/sports',
      icon: Icons.live_tv,
      brandColor: Color(0xFF0066CC),
    ),
    BroadcasterInfo(
      name: 'ESPN+ / Star+',
      region: 'United States & Americas',
      regionCode: 'US',
      platform: 'ESPN App & Star+',
      coverage: 'La Liga, Bundesliga & FA Cup',
      url: 'https://plus.espn.com',
      icon: Icons.sports_football,
      brandColor: Color(0xFFD40000),
    ),
    BroadcasterInfo(
      name: 'SuperSport Premier League',
      region: 'Sub-Saharan Africa',
      regionCode: 'AF',
      platform: 'DStv Stream / GOtv',
      coverage: 'Live African & Global Football',
      url: 'https://supersport.com/live',
      icon: Icons.tv,
      brandColor: Color(0xFF1E88E5),
    ),
    BroadcasterInfo(
      name: 'beIN Sports 1 HD Premium',
      region: 'Middle East & North Africa (MENA)',
      regionCode: 'ME',
      platform: 'beIN CONNECT / TOD TV',
      coverage: 'Arabic & English Live Broadcast',
      url: 'https://connect.beinsports.com',
      icon: Icons.live_tv,
      brandColor: Color(0xFF6A1B9A),
    ),
    BroadcasterInfo(
      name: 'DAZN Sports',
      region: 'Spain, Germany & Europe',
      regionCode: 'EU',
      platform: 'DAZN App & Web',
      coverage: 'La Liga, Serie A & Champions League',
      url: 'https://www.dazn.com',
      icon: Icons.sports,
      brandColor: Color(0xFFF8B500),
    ),
    BroadcasterInfo(
      name: 'FIFA+ Official Streaming',
      region: 'Worldwide / International',
      regionCode: 'GLOBAL',
      platform: 'FIFA+ Free Stream',
      coverage: 'Free Domestic Leagues & Highlights',
      url: 'https://www.plus.fifa.com',
      icon: Icons.public,
      brandColor: Color(0xFF00B0FF),
    ),
  ];

  Future<void> _openBroadcaster(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedRegion == 'ALL'
        ? _broadcasters
        : _broadcasters.where((b) => b.regionCode == _selectedRegion).toList();

    return Container(
      color: const Color(0xFF121212),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.secondary, Color(0xFF1E2638)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.satellite_alt, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'OFFICIAL TV & BROADCAST GUIDE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.matchTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Verified official television stations and licensed streaming apps broadcasting this fixture live.',
                  style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Region Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRegionChip('ALL', '🌐 All Regions'),
                _buildRegionChip('UK', '🇬🇧 UK & Ireland'),
                _buildRegionChip('US', '🇺🇸 USA'),
                _buildRegionChip('AF', '🌍 Africa'),
                _buildRegionChip('ME', '🌍 Middle East'),
                _buildRegionChip('EU', '🇪🇸 Europe'),
                _buildRegionChip('GLOBAL', '🌐 Global Free'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Broadcaster List Cards
          ...filtered.map((b) => _buildBroadcasterCard(b)),

          const SizedBox(height: 20),

          // LiveSoccerTV Button
          Card(
            color: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.public, color: Colors.cyanAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Worldwide TV Schedule Directory',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Need schedules for a specific country or local channel? Browse global listings across 190+ countries.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Open Global Broadcast Listings'),
                      onPressed: () {
                        final encoded = Uri.encodeComponent(widget.matchTitle);
                        _openBroadcaster('https://m.livesoccertv.com/search/?q=$encoded');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRegionChip(String code, String label) {
    final isSelected = _selectedRegion == code;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white12,
        checkmarkColor: Colors.black,
        onSelected: (_) => setState(() => _selectedRegion = code),
      ),
    );
  }

  Widget _buildBroadcasterCard(BroadcasterInfo b) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: b.brandColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: b.brandColor.withOpacity(0.6)),
              ),
              child: Icon(b.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${b.region} • ${b.platform}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          b.coverage,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.launch, color: AppColors.primary, size: 20),
              tooltip: 'Open Broadcaster',
              onPressed: () => _openBroadcaster(b.url),
            ),
          ],
        ),
      ),
    );
  }
}
