import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  AdManager._();
  static final AdManager instance = AdManager._();

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  // Unit IDs (Move yours here)
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _prodInterstitialId = 'ca-app-pub-4377808055186677/2712849317';

  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _prodBannerId = 'ca-app-pub-4377808055186677/5698105305';

  String get interstitialAdUnitId => kDebugMode ? _testInterstitialId : _prodInterstitialId;
  String get bannerAdUnitId => kDebugMode ? _testBannerId : _prodBannerId;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    loadInterstitialAd();
  }

  void loadInterstitialAd() {
    if (_isInterstitialLoading || _interstitialAd != null) return;

    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
          debugPrint('[AdManager] Interstitial loaded.');
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          debugPrint('[AdManager] Interstitial failed to load: $error');
          // Retry after delay
          Future.delayed(const Duration(seconds: 10), loadInterstitialAd);
        },
      ),
    );
  }

  Future<void> showInterstitialAd() async {
    if (_interstitialAd == null) {
      debugPrint('[AdManager] Interstitial not ready.');
      loadInterstitialAd();
      return;
    }
    await _interstitialAd!.show();
  }
}

/// A wrapper class to match the existing usage in generator_screen.dart if needed,
/// or just used directly as AdManager.instance
class InterstitialAdManager {
  static Future<void> showInterstitialAd() => AdManager.instance.showInterstitialAd();
}
