import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/admob_service.dart';

class MediumRectangleAdWidget extends StatefulWidget {
  const MediumRectangleAdWidget({super.key});

  @override
  State<MediumRectangleAdWidget> createState() => _MediumRectangleAdWidgetState();
}

class _MediumRectangleAdWidgetState extends State<MediumRectangleAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdMobService.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.mediumRectangle,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('MediumRectangle ad failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 250,
      width: 300,
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
