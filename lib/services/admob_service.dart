import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class AdMobService {
  Future<void> init() async {
    await MobileAds.instance.initialize();
    debugPrint('AdMob Initialized');
  }

  // Banner Ad Unit ID
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-5162704187856871/8043001266';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // iOS Test ID
    }
    return '';
  }

  // Interstitial Ad Unit ID
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-5162704187856871/6151335093';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // iOS Test ID
    }
    return '';
  }

  // Rewarded Ad Unit ID
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-5162704187856871/9547654625';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // iOS Test ID
    }
    return '';
  }

  // Rewarded Interstitial Ad Unit ID
  static String get rewardedInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-5162704187856871/2905950382';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/6978759866'; // iOS Test ID
    }
    return '';
  }
}
