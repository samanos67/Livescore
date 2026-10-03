import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class InterstitialAdService {
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  int _numInterstitialLoadAttempts = 0;
  static const int maxFailedLoadAttempts = 3;

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test ID
    }
    return '';
  }

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

  void showAd() {
    if (_isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      debugPrint('Interstitial ad not ready yet');
      loadAd();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}
