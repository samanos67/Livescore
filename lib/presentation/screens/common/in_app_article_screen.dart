import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/news_article.dart';

class InAppArticleScreen extends StatefulWidget {
  final NewsArticle article;

  const InAppArticleScreen({super.key, required this.article});

  @override
  State<InAppArticleScreen> createState() => _InAppArticleScreenState();
}

class _InAppArticleScreenState extends State<InAppArticleScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() => _progress = progress / 100);
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
            // In-app Ad and popup suppression shield
            _controller.runJavaScript('''
              try {
                window.open = function() { return null; };
                var ads = document.querySelectorAll('iframe[src*="ad"], .ad-container, .advert, .advertisement, div[id*="google_ads"]');
                ads.forEach(function(el) { el.style.display = 'none'; });
              } catch(e) {}
            ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            final lower = request.url.toLowerCase();
            // Block external intent redirects so users stay in the app
            if (lower.startsWith('intent://') ||
                lower.startsWith('market://') ||
                lower.contains('adsterra') ||
                lower.contains('betway') ||
                lower.contains('onclick')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.article.url));
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: widget.article.url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Article link copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.article.source.isNotEmpty ? widget.article.source : 'LiveScore News',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            Text(
              widget.article.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Reload',
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.share, size: 20),
            tooltip: 'Share',
            onPressed: _copyLink,
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3.0),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  backgroundColor: AppColors.secondary,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 3,
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
