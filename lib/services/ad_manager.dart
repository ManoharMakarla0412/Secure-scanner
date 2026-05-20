import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';

/// AdManager handles all ad preloading and display logic.
/// It uses a singleton pattern and listens to app lifecycle events.
class AdManager with WidgetsBindingObserver {
  AdManager._();
  static final AdManager instance = AdManager._();

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  AppOpenAd? _appOpenAd;
  bool _isAppOpenAdLoading = false;
  DateTime? _appOpenAdLoadTime;

  // Scan counter to avoid spamming ads every single scan (Improved Retention)
  int _scanCounter = 0;
  static const int _adEveryXScans = 2; // Show ad every 2nd successful scan

  // Unit IDs (Aligned with App ID: ca-app-pub-2961863855425096~9911328154)
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _prodInterstitialId = 'ca-app-pub-2961863855425096/8982046403';

  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _prodBannerId = 'ca-app-pub-2961863855425096/5968213716';

  static const String _testAppOpenId = 'ca-app-pub-3940256099942544/9257395921';
  static const String _prodAppOpenId = 'ca-app-pub-2961863855425096/3063505313';

  String get interstitialAdUnitId => kDebugMode ? _testInterstitialId : _prodInterstitialId;
  String get bannerAdUnitId => kDebugMode ? _testBannerId : _prodBannerId;
  String get appOpenAdUnitId => kDebugMode ? _testAppOpenId : _prodAppOpenId;

  /// Initialize AdMob and start preloading.
  /// Called once at app startup.
  Future<void> init() async {
    try {
      final status = await MobileAds.instance.initialize();
      debugPrint('[AdManager] AdMob Initialized: ${status.adapterStatuses}');
      
      // Small delay to ensure SDK internal setup is complete
      await Future.delayed(const Duration(milliseconds: 500));
      
      loadInterstitialAd();
      loadAppOpenAd();
    } catch (e) {
      debugPrint('[AdManager] Initialization failed: $e');
    }

    // Start listening to app state changes for App Open Ads
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[AdManager] App resumed. Triggering App Open Ad check.');
      showAppOpenAdIfAvailable();
    }
  }

  /// Load the interstitial ad with better error handling.
  void loadInterstitialAd() {
    if (_isInterstitialLoading || _interstitialAd != null) {
      return;
    }

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
              loadInterstitialAd(); // Preload next immediately
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
          FirebaseAnalytics.instance.logEvent(name: 'ad_loaded', parameters: {'type': 'interstitial'});
          debugPrint('[AdManager] Interstitial loaded.');
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          _interstitialAd = null;
          FirebaseAnalytics.instance.logEvent(
            name: 'ad_failed_to_load',
            parameters: {'type': 'interstitial', 'error': error.message},
          );
          debugPrint('[AdManager] Interstitial failed: ${error.message}');
          // Retry later
          Future.delayed(const Duration(seconds: 15), loadInterstitialAd);
        },
      ),
    );
  }

  /// Show Interstitial with scan counter logic and "Wait with Timeout" (Improved Ad Impressions)
  Future<void> showInterstitialAd({bool force = false}) async {
    _scanCounter++;
    debugPrint('[AdManager] Current Scan Counter: $_scanCounter (Every $_adEveryXScans)');

    if (!force && _scanCounter % _adEveryXScans != 0) {
      debugPrint('[AdManager] Skipping ad for current scan.');
      return;
    }

    // "Wait with Timeout" logic: If an ad is almost loaded, wait 500ms instead of skipping
    if (_interstitialAd == null && _isInterstitialLoading) {
      debugPrint('[AdManager] Ad is loading. waiting 700ms...');
      int waitMs = 0;
      while (_interstitialAd == null && waitMs < 700) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitMs += 100;
      }
    }

    if (_interstitialAd == null) {
      debugPrint('[AdManager] Interstitial still not ready. Skipping.');
      loadInterstitialAd();
      return;
    }

    debugPrint('[AdManager] Showing Interstitial...');
    FirebaseAnalytics.instance.logEvent(name: 'ad_shown', parameters: {'type': 'interstitial'});
    _interstitialAd!.show().catchError((e) {
      FirebaseAnalytics.instance.logEvent(name: 'ad_failed_to_show', parameters: {'type': 'interstitial', 'error': e.toString()});
      debugPrint('[AdManager] Error showing ad: $e');
    });
  }

  void loadAppOpenAd() {
    if (_isAppOpenAdLoading || _appOpenAd != null) return;

    _isAppOpenAdLoading = true;
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAppOpenAdLoading = false;
          _appOpenAdLoadTime = DateTime.now();
          FirebaseAnalytics.instance.logEvent(name: 'ad_loaded', parameters: {'type': 'app_open'});
          debugPrint('[AdManager] App Open Ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _isAppOpenAdLoading = false;
          FirebaseAnalytics.instance.logEvent(
            name: 'ad_failed_to_load',
            parameters: {'type': 'app_open', 'error': error.message},
          );
          debugPrint('[AdManager] App Open Ad failed: ${error.message}');
          Future.delayed(const Duration(seconds: 30), loadAppOpenAd);
        },
      ),
    );
  }

  /// Shows App Open Ad if available and not expired
  void showAppOpenAdIfAvailable() {
    if (_appOpenAd == null) {
      loadAppOpenAd();
      return;
    }

    // Check expiration (4 hours limit for App Open Ads)
    if (_appOpenAdLoadTime != null &&
        DateTime.now().difference(_appOpenAdLoadTime!).inHours >= 4) {
      _appOpenAd!.dispose();
      _appOpenAd = null;
      loadAppOpenAd();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );

    FirebaseAnalytics.instance.logEvent(name: 'ad_shown', parameters: {'type': 'app_open'});
    _appOpenAd!.show();
  }
}

/// Compatibility wrapper for existing usages or App Lifecycle Events
class AppStateEventNotifier {
  // We keep this class to avoid build errors if it was referenced, 
  // but we point it to the main singleton logic.
  static void startListening() {
    // AdManager already initializes its observer in init().
  }
}

class InterstitialAdManager {
  static Future<void> showInterstitialAd() => AdManager.instance.showInterstitialAd();
}

/// Stub/Legacy notifier removed as it was not defined
/// Use AdManager.instance directly as it now handles lifecycle
