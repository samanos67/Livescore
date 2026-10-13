import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/stream_provider.dart';
import 'video_player_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/banner_ad_widget.dart';

class LiveTvScreen extends ConsumerStatefulWidget {
  const LiveTvScreen({super.key});

  @override
  ConsumerState<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends ConsumerState<LiveTvScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  void _showAddStreamDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.secondary,
          title: const Row(
            children: [
              Icon(Icons.add_link, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Add Stream Link', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Match / Channel Title',
                  hintText: 'e.g. Arsenal vs Chelsea Live',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Stream URL / Link',
                  hintText: 'https://...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final title = _titleController.text.trim();
                final url = _urlController.text.trim();
                if (title.isNotEmpty && url.isNotEmpty) {
                  ref.read(customStreamsProvider.notifier).addCustomStream(title, url);
                  _titleController.clear();
                  _urlController.clear();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stream added successfully!')),
                  );
                }
              },
              child: const Text('Add Stream'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streamsAsync = ref.watch(allStreamsProvider);

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
            const Text('Live TV & Streams', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Custom Stream',
            onPressed: () => _showAddStreamDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Streams',
            onPressed: () => ref.invalidate(allStreamsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_link, color: Colors.black),
        label: const Text(
          'Add Stream',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showAddStreamDialog(context),
      ),
      bottomNavigationBar: const BannerAdWidget(),
      body: streamsAsync.when(
        data: (streams) {
          if (streams.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/telegram_banner.png',
                        width: 220,
                        height: 124,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('No live streams found currently.', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _showAddStreamDialog(context),
                      child: const Text('Add Stream Link'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allStreamsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount: streams.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildTelegramHeroBanner(context);
                }
                if (index == 1) {
                  return _buildTvGuideSection(context);
                }
                final channel = streams[index - 2];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  color: AppColors.cardBackground,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerScreen(
                            title: channel.title,
                            streamUrl: channel.primaryStreamUrl,
                            servers: channel.servers,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl: channel.thumbnailUrl,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                height: 180,
                                color: Colors.grey[900],
                                child: const Center(
                                  child: CircularProgressIndicator(color: AppColors.primary),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                height: 180,
                                color: Colors.grey[900],
                                child: const Icon(Icons.sports_soccer, size: 48, color: Colors.white24),
                              ),
                            ),
                            // Dark gradient overlay
                            Container(
                              height: 180,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.8),
                                  ],
                                ),
                              ),
                            ),
                            // Live Badge
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.circle, color: Colors.white, size: 8),
                                    SizedBox(width: 5),
                                    Text(
                                      'LIVE STREAM',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Play icon centered
                            Positioned.fill(
                              child: Center(
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                channel.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.sports, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      channel.competition,
                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    channel.date,
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading streams: $err')),
      ),
    );
  }

  Widget _buildTelegramHeroBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0088CC),
            Color(0xFF005580),
            Color(0xFF0F172A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0088CC).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Color(0xFF0088CC), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Live Match Streams on Telegram',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'FREE',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Join our official Telegram community for instant HD match stream links, live commentary, and real-time video clips.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0088CC),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.launch, size: 18),
                  label: const Text(
                    'Join Telegram Stream Channel',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () async {
                    const telegramUrl = 'https://t.me/livescore_official_streams';
                    final uri = Uri.parse(telegramUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening Telegram channel...')),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTvGuideSection(BuildContext context) {
    final broadcasters = [
      {'league': 'Premier League', 'channels': 'Sky Sports, TNT Sports, NBC, Peacock'},
      {'league': 'UEFA Champions League', 'channels': 'TNT Sports, Paramount+, DAZN'},
      {'league': 'La Liga', 'channels': 'ESPN+, Premier Sports, DAZN'},
      {'league': 'Serie A & Bundesliga', 'channels': 'CBS Sports, Paramount+, ESPN+'},
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tv, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Official TV Broadcast Guide',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final b in broadcasters)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${b['league']}: ',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        b['channels']!,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            const Text(
              'Tune into authorized broadcasters in your country for 4K/HD television coverage.',
              style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

