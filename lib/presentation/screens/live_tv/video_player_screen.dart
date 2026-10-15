import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../domain/entities/live_stream_channel.dart';
import '../../widgets/broadcast_guide_widget.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../../main.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String? videoId;
  final String? streamUrl;
  final String title;
  final String? matchQuery;
  final List<StreamServer>? servers;

  const VideoPlayerScreen({
    super.key,
    this.videoId,
    this.streamUrl,
    required this.title,
    this.matchQuery,
    this.servers,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _ytController;
  WebViewController? _webController;
  bool _isLoading = true;
  int _selectedServerIndex = 0;
  late List<StreamServer> _availableServers;

  @override
  void initState() {
    super.initState();
    _initServers();
    _loadCurrentServer();
  }

  void _initServers() {
    if (widget.servers != null && widget.servers!.isNotEmpty) {
      _availableServers = List.from(widget.servers!);
    } else if (widget.streamUrl != null) {
      _availableServers = [
        StreamServer(name: 'Server 1: Direct Stream', url: widget.streamUrl!),
        const StreamServer(
          name: 'Server 2: TV Broadcast Guide',
          url: 'broadcast-guide',
        ),
        const StreamServer(
          name: 'Server 3: LiveSoccerTV Index',
          url: 'https://m.livesoccertv.com',
        ),
      ];
    } else if (widget.videoId != null) {
      _availableServers = [
        StreamServer(name: 'YouTube HD Stream', url: widget.videoId!),
        const StreamServer(
          name: 'Server 2: TV Broadcast Guide',
          url: 'broadcast-guide',
        ),
      ];
    } else if (widget.matchQuery != null) {
      final encodedMatch = Uri.encodeComponent(widget.matchQuery!);
      final encodedHighlights = Uri.encodeComponent('${widget.title} goals highlights match recap');
      final encodedTitle = Uri.encodeComponent(widget.title);

      _availableServers = [
        StreamServer(
          name: 'Server 1: Live Stream (YouTube)',
          url: 'https://www.youtube.com/results?search_query=$encodedMatch',
        ),
        const StreamServer(
          name: 'Server 2: TV Broadcast Guide',
          url: 'broadcast-guide',
        ),
        StreamServer(
          name: 'Server 3: Goals & Highlights',
          url: 'https://www.youtube.com/results?search_query=$encodedHighlights',
        ),
        StreamServer(
          name: 'Server 4: Live Match Centre',
          url: 'https://m.livesoccertv.com/search/?q=$encodedTitle',
        ),
      ];
    } else {
      _availableServers = [
        const StreamServer(name: 'Server 1: FIFA+ Live', url: 'https://www.plus.fifa.com'),
        const StreamServer(name: 'Server 2: TV Broadcast Guide', url: 'broadcast-guide'),
      ];
    }
  }

  void _loadCurrentServer() {
    final server = _availableServers[_selectedServerIndex];
    final url = server.url;

    if (url == 'broadcast-guide') {
      _ytController?.dispose();
      _ytController = null;
      _webController = null;
      setState(() => _isLoading = false);
      return;
    }

    // Check if URL is an 11-char YouTube ID or full YouTube URL
    String? ytId = widget.videoId;
    if (ytId == null || ytId.isEmpty) {
      ytId = YoutubePlayer.convertUrlToId(url);
    }
    if (ytId == null && url.length == 11 && !url.startsWith('http')) {
      ytId = url;
    }

    if (ytId != null && ytId.isNotEmpty) {
      _ytController?.dispose();
      _ytController = YoutubePlayerController(
        initialVideoId: ytId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          isLive: false,
          enableCaption: false,
        ),
      );
      setState(() => _isLoading = false);
      return;
    } else {
      _ytController?.dispose();
      _ytController = null;
      setState(() => _isLoading = true);

      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) => setState(() => _isLoading = true),
            onPageFinished: (_) {
              setState(() => _isLoading = false);
              // In-App Ad-Shield: suppress popup tabs and intrusive overlay banners
              _webController?.runJavaScript('''
                try {
                  window.open = function() { return null; };
                  var adSelectors = ['iframe[src*="ad"]', 'iframe[src*="doubleclick"]', 'div[class*="ad-"]', 'div[id*="ad-"]', '.ad-banner'];
                  adSelectors.forEach(function(sel) {
                    document.querySelectorAll(sel).forEach(function(el) { el.style.display = 'none'; });
                  });
                } catch(e) {}
              ''');
            },
            onNavigationRequest: (NavigationRequest request) {
              final lower = request.url.toLowerCase();
              // Prevent malicious spam popups and gambling redirects
              if (lower.contains('adsterra') ||
                  lower.contains('betway') ||
                  lower.contains('onclick') ||
                  lower.contains('popunder') ||
                  lower.contains('tracker') ||
                  lower.contains('monetag') ||
                  lower.contains('syndication') ||
                  lower.startsWith('intent://') ||
                  lower.startsWith('market://')) {
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
            onWebResourceError: (_) => setState(() => _isLoading = false),
          ),
        )
        ..loadRequest(Uri.parse(url));
    }
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  Future<void> _openExternal() async {
    final server = _availableServers[_selectedServerIndex];
    if (server.url == 'broadcast-guide') {
      final encoded = Uri.encodeComponent(widget.title);
      final uri = Uri.parse('https://m.livesoccertv.com/search/?q=$encoded');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    final target = server.url.startsWith('http')
        ? server.url
        : 'https://www.youtube.com/watch?v=${server.url}';
    final uri = Uri.parse(target);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showAddCustomServerDialog() {
    final nameCtrl = TextEditingController(text: 'Server ${_availableServers.length + 1}');
    final urlCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.secondary,
        title: const Text('Add Custom Stream Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Server Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(labelText: 'Stream / HLS URL'),
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
              final name = nameCtrl.text.trim();
              final url = urlCtrl.text.trim();
              if (name.isNotEmpty && url.isNotEmpty) {
                setState(() {
                  _availableServers.add(StreamServer(name: name, url: url));
                  _selectedServerIndex = _availableServers.length - 1;
                });
                Navigator.pop(ctx);
                _loadCurrentServer();
              }
            },
            child: const Text('Add & Switch'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentServer = _availableServers[_selectedServerIndex];
    final isBroadcastGuide = currentServer.url == 'broadcast-guide';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link),
            tooltip: 'Add Custom Stream Server',
            onPressed: _showAddCustomServerDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Stream',
            onPressed: () {
              if (_webController != null) {
                _webController!.reload();
              } else {
                _loadCurrentServer();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Open in External Browser',
            onPressed: _openExternal,
          ),
        ],
      ),
      body: Column(
        children: [
          // Server Selection Bar
          Container(
            color: AppColors.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.dns, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Server:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_availableServers.length, (index) {
                        final isSelected = index == _selectedServerIndex;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              _availableServers[index].name,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.white12,
                            onSelected: (val) {
                              if (val && _selectedServerIndex != index) {
                                setState(() {
                                  _selectedServerIndex = index;
                                });
                                _loadCurrentServer();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main View: Video Player or Broadcast Guide
          if (isBroadcastGuide)
            Expanded(
              child: BroadcastGuideWidget(matchTitle: widget.title),
            )
          else ...[
            // Video Player Container (Aspect ratio 16:9)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: Stack(
                  children: [
                    if (_ytController != null)
                      YoutubePlayer(
                        controller: _ytController!,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: Colors.red,
                      )
                    else if (_webController != null)
                      WebViewWidget(controller: _webController!)
                    else
                      const Center(child: Text('Stream unavailable', style: TextStyle(color: Colors.white))),
                    if (_isLoading)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Controls & Tips section
            Expanded(
              child: Container(
                color: const Color(0xFF121212),
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Colors.white, size: 8),
                              SizedBox(width: 4),
                              Text(
                                'LIVE FEED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Quick Switch to TV Broadcast Guide Banner
                    InkWell(
                      onTap: () {
                        // Find broadcast guide index
                        final idx = _availableServers.indexWhere((s) => s.url == 'broadcast-guide');
                        if (idx != -1) {
                          setState(() => _selectedServerIndex = idx);
                          _loadCurrentServer();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.satellite_alt, color: AppColors.primary, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'View Official TV Broadcasters',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    'Find legal Sky, beIN, SuperSport & Peacock feeds in your region.',
                                    style: TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Streaming Tips Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shield, size: 16, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text(
                                'In-App Ad-Shield Active',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            '• Pop-up ads and external redirects are automatically blocked.\n'
                            '• Server 1 searches live YouTube streams and community commentary.\n'
                            '• Server 3 streams instant match highlights and goal replays.\n'
                            '• Tap the top-right link icon to add your own custom M3U8/IPTV stream.',
                            style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Telegram Live Streams Banner Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0088CC).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF0088CC).withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0088CC),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Live Streams on Telegram',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Join our channel for instant HD match links & goal clips',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0088CC),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              final uri = Uri.parse(ApiConstants.telegramChannelUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: const Text('JOIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Voluntary Rewarded Ad Sponsor Card (High eCPM, 100% voluntary)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary.withOpacity(0.15), AppColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.primary, size: 24),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Support Live Broadcasts',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                ),
                                Text(
                                  'Watch a quick sponsor clip to keep live streams running free!',
                                  style: TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            onPressed: () {
                              rewardedAdService.showRewardedAd(
                                onRewardEarned: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('🎉 Thank you for supporting free match streaming!'),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                },
                              );
                            },
                            child: const Text('WATCH'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}
