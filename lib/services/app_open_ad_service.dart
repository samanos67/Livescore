import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class AppOpenAdService {
  AppOpenAd? _appOpenAd;
  bool _isAdLoaded = false;
  DateTime? _appOpenLoadTime;
  static const int maxCacheDuration = 4; // hours

  static String get appOpenAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/9257395921'; // Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/5575463023'; // Test ID
    }
    return '';
  }

  void loadAd() {
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('App open ad loaded');
          _appOpenAd = ad;
          _isAdLoaded = true;
          _appOpenLoadTime = DateTime.now();
          _setAdCallbacks();
        },
        onAdFailedToLoad: (error) {
          debugPrint('App open ad failed to load: $error');
          _isAdLoaded = false;
        },
      ),
    );
  }

  void _setAdCallbacks() {
    _appOpenAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('App open ad showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('App open ad dismissed');
        ad.dispose();
        _isAdLoaded = false;
        _appOpenAd = null;
        loadAd(); // Load next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('App open ad failed to show: $error');
        ad.dispose();
        _isAdLoaded = false;
        _appOpenAd = null;
        loadAd();
      },
    );
  }

  bool get isAdAvailable {
    if (!_isAdLoaded || _appOpenAd == null) return false;
    
    // Check if ad is too old
    if (_appOpenLoadTime != null) {
      final duration = DateTime.now().difference(_appOpenLoadTime!);
      if (duration.inHours >= maxCacheDuration) {
        _appOpenAd?.dispose();
        _appOpenAd = null;
        _isAdLoaded = false;
        return false;
      }
    }
    
    return true;
  }

  void showAdIfAvailable() {
    if (isAdAvailable) {
      _appOpenAd!.show();
    } else {
      debugPrint('App open ad not ready');
      loadAd();
    }
  }

  void dispose() {
    _appOpenAd?.dispose();
  }
}
