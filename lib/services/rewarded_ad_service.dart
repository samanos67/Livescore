import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'admob_service.dart';

class RewardedAdService {
  RewardedAd? _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;
  
  bool _isRewardedLoaded = false;
  bool _isRewardedInterstitialLoaded = false;
  
  int _rewardedLoadAttempts = 0;
  int _rewardedInterstitialLoadAttempts = 0;
  static const int maxFailedLoadAttempts = 3;

  bool get isRewardedLoaded => _isRewardedLoaded;
  bool get isRewardedInterstitialLoaded => _isRewardedInterstitialLoaded;

  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdMobService.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Rewarded ad loaded');
          _rewardedAd = ad;
          _isRewardedLoaded = true;
          _rewardedLoadAttempts = 0;
          _setRewardedCallbacks();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedLoadAttempts++;
          _rewardedAd = null;
          _isRewardedLoaded = false;
          if (_rewardedLoadAttempts < maxFailedLoadAttempts) {
            Future.delayed(const Duration(seconds: 5), loadRewardedAd);
          }
        },
      ),
    );
  }

  void _setRewardedCallbacks() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('Rewarded ad showed full screen');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Rewarded ad dismissed');
        ad.dispose();
        _isRewardedLoaded = false;
        _rewardedAd = null;
        loadRewardedAd(); // Preload next
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: $error');
        ad.dispose();
        _isRewardedLoaded = false;
        _rewardedAd = null;
        loadRewardedAd();
      },
    );
  }

  void showRewardedAd({
    required VoidCallback onRewardEarned,
    VoidCallback? onAdDismissed,
  }) {
    if (_isRewardedLoaded && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isRewardedLoaded = false;
          _rewardedAd = null;
          loadRewardedAd();
          onAdDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isRewardedLoaded = false;
          _rewardedAd = null;
          loadRewardedAd();
          onAdDismissed?.call();
        },
      );
      _rewardedAd!.show(
        onUserEarnedReward: (adWithoutView, reward) {
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          onRewardEarned();
        },
      );
    } else {
      debugPrint('Rewarded ad not loaded yet, triggering load');
      loadRewardedAd();
      // Gracefully continue so user is never blocked
      onRewardEarned();
    }
  }

  void loadRewardedInterstitialAd() {
    RewardedInterstitialAd.load(
      adUnitId: AdMobService.rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Rewarded Interstitial ad loaded');
          _rewardedInterstitialAd = ad;
          _isRewardedInterstitialLoaded = true;
          _rewardedInterstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded Interstitial ad failed to load: $error');
          _rewardedInterstitialLoadAttempts++;
          _rewardedInterstitialAd = null;
          _isRewardedInterstitialLoaded = false;
          if (_rewardedInterstitialLoadAttempts < maxFailedLoadAttempts) {
            Future.delayed(const Duration(seconds: 5), loadRewardedInterstitialAd);
          }
        },
      ),
    );
  }

  void showRewardedInterstitialAd({
    required VoidCallback onRewardEarned,
    VoidCallback? onAdDismissed,
  }) {
    if (_isRewardedInterstitialLoaded && _rewardedInterstitialAd != null) {
      _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isRewardedInterstitialLoaded = false;
          _rewardedInterstitialAd = null;
          loadRewardedInterstitialAd();
          onAdDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isRewardedInterstitialLoaded = false;
          _rewardedInterstitialAd = null;
          loadRewardedInterstitialAd();
          onAdDismissed?.call();
        },
      );
      _rewardedInterstitialAd!.show(
        onUserEarnedReward: (adWithoutView, reward) {
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          onRewardEarned();
        },
      );
    } else {
      debugPrint('Rewarded Interstitial ad not ready, triggering load');
      loadRewardedInterstitialAd();
      onRewardEarned();
    }
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedInterstitialAd?.dispose();
  }
}
