import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'admob_service.dart';

class InterstitialAdService {
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  int _numInterstitialLoadAttempts = 0;
  static const int maxFailedLoadAttempts = 3;

  static String get interstitialAdUnitId => AdMobService.interstitialAdUnitId;

  void loadAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial ad loaded');
          _interstitialAd = ad;
          _isAdLoaded = true;
          _numInterstitialLoadAttempts = 0;
          _setAdCallbacks();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _numInterstitialLoadAttempts += 1;
          _interstitialAd = null;
          _isAdLoaded = false;
          
          if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
            Future.delayed(const Duration(seconds: 5), loadAd);
          }
        },
      ),
    );
  }

  void _setAdCallbacks() {
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('Interstitial ad showed full screen content');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Interstitial ad dismissed');
        ad.dispose();
        _isAdLoaded = false;
        loadAd(); // Load next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial ad failed to show: $error');
        ad.dispose();
        _isAdLoaded = false;
        loadAd();
      },
    );
  }

  int _actionCount = 0;
  DateTime? _lastAdShownTime;

  void showAd({VoidCallback? onDismissed}) {
    if (_isLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('Interstitial ad showed');
          _lastAdShownTime = DateTime.now();
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('Interstitial ad dismissed');
          ad.dispose();
          _isAdLoaded = false;
          _interstitialAd = null;
          loadAd();
          onDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Interstitial ad failed to show: $error');
          ad.dispose();
          _isAdLoaded = false;
          _interstitialAd = null;
          loadAd();
          onDismissed?.call();
        },
      );
      _interstitialAd!.show();
    } else {
      debugPrint('Interstitial ad not ready yet');
      loadAd();
      onDismissed?.call();
    }
  }

  /// Shows the interstitial ad only every [interval] user actions
  /// and respects a minimum cooldown of [cooldown] (default 2.5 minutes)
  void showAdWithFrequencyCap({
    int interval = 4,
    Duration cooldown = const Duration(seconds: 150),
    VoidCallback? onDismissed,
  }) {
    _actionCount++;
    final now = DateTime.now();
    final timePassed = _lastAdShownTime == null || now.difference(_lastAdShownTime!) >= cooldown;

    if (_actionCount >= interval && timePassed && _isAdLoaded) {
      _actionCount = 0;
      showAd(onDismissed: onDismissed);
    } else {
      onDismissed?.call();
    }
  }

  bool get _isLoaded => _isAdLoaded && _interstitialAd != null;

  void dispose() {
    _interstitialAd?.dispose();
  }
}
