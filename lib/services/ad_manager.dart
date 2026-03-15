import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  AdManager._();
  static final AdManager instance = AdManager._();

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  AppOpenAd? _appOpenAd;
  bool _isAppOpenAdLoading = false;
  DateTime? _appOpenAdLoadTime;

  // Unit IDs (Aligned with App ID in AndroidManifest: ca-app-pub-2961863855425096~9911328154)
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _prodInterstitialId = 'ca-app-pub-2961863855425096/8982046403';

  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _prodBannerId = 'ca-app-pub-2961863855425096/5968213716';

  static const String _testAppOpenId = 'ca-app-pub-3940256099942544/9257395921';
  static const String _prodAppOpenId = 'ca-app-pub-2961863855425096/3063505313';

  String get interstitialAdUnitId => kDebugMode ? _testInterstitialId : _prodInterstitialId;
  String get bannerAdUnitId => kDebugMode ? _testBannerId : _prodBannerId;
  String get appOpenAdUnitId => kDebugMode ? _testAppOpenId : _prodAppOpenId;

  Future<void> init() async {
    final status = await MobileAds.instance.initialize();
    debugPrint('[AdManager] Initialized: ${status.adapterStatuses}');
    loadInterstitialAd();
    loadAppOpenAd();

    // Listen to app state changes to show App Open Ad
    AppStateEventNotifier.startListening();
    AppStateEventNotifier.appStateStream.listen((state) {
      if (state == AppState.foreground) {
        showAppOpenAdIfAvailable();
      }
    });
  }

  void loadInterstitialAd() {
    if (_isInterstitialLoading || _interstitialAd != null) return;

    _isInterstitialLoading = true;
    debugPrint('[AdManager] Loading interstitial: $interstitialAdUnitId');
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('[AdManager] Interstitial dismissed.');
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('[AdManager] Interstitial failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
          debugPrint('[AdManager] Interstitial loaded.');
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          debugPrint('[AdManager] Interstitial failed to load: Code ${error.code}, Message: ${error.message}, Domain: ${error.domain}');
          // Retry after delay
          Future.delayed(const Duration(seconds: 30), loadInterstitialAd);
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

  /// Load App Open Ad
  void loadAppOpenAd() {
    if (_isAppOpenAdLoading || _appOpenAd != null) return;

    _isAppOpenAdLoading = true;
    debugPrint('[AdManager] Loading App Open Ad: $appOpenAdUnitId');

    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdManager] App Open Ad loaded.');
          _appOpenAd = ad;
          _isAppOpenAdLoading = false;
          _appOpenAdLoadTime = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdManager] App Open Ad failed to load: $error');
          _isAppOpenAdLoading = false;
          // Retry after 30 seconds
          Future.delayed(const Duration(seconds: 30), loadAppOpenAd);
        },
      ),
    );
  }

  /// Show App Open Ad if available
  void showAppOpenAdIfAvailable() {
    if (_appOpenAd == null) {
      debugPrint('[AdManager] App Open Ad is not loaded yet.');
      loadAppOpenAd();
      return;
    }

    // Check if ad is expired (e.g., loaded more than 4 hours ago)
    if (_appOpenAdLoadTime != null &&
        DateTime.now().difference(_appOpenAdLoadTime!).inHours >= 4) {
      debugPrint('[AdManager] App Open Ad expired. Disposing and reloading.');
      _appOpenAd!.dispose();
      _appOpenAd = null;
      loadAppOpenAd();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[AdManager] App Open Ad showed.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdManager] App Open Ad dismissed.');
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdManager] App Open Ad failed to show: $error');
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );

    _appOpenAd!.show();
  }
}

/// A wrapper class to match the existing usage in generator_screen.dart if needed,
/// or just used directly as AdManager.instance
class InterstitialAdManager {
  static Future<void> showInterstitialAd() => AdManager.instance.showInterstitialAd();
}
