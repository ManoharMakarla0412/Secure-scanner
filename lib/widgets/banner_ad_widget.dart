import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:securescan/services/ad_manager.dart';

class BannerAdWidget extends StatefulWidget {
  final AdSize adSize;
  final String? adUnitId;

  const BannerAdWidget({
    super.key,
    this.adSize = AdSize.largeBanner,
    this.adUnitId,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  int _retryAttempts = 0;
  static const int _maxRetries = 5;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adUnitId = widget.adUnitId ?? AdManager.instance.bannerAdUnitId;
    
    if (adUnitId.isEmpty) {
      debugPrint('[BannerAdWidget] Error: Ad Unit ID is empty.');
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('[BannerAdWidget] Ad loaded successfully: ${ad.adUnitId}');
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _isLoaded = true;
            _retryAttempts = 0;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[BannerAdWidget] Failed to load (${ad.adUnitId}): Code ${error.code}, Message: ${error.message}');
          ad.dispose();
          _bannerAd = null;
          
          if (!mounted) return;

          setState(() {
            _isLoaded = false;
          });

          // Exponential backoff retry
          if (_retryAttempts < _maxRetries) {
            _retryAttempts++;
            final delaySeconds = _retryAttempts * 10;
            debugPrint('[BannerAdWidget] Retrying in $delaySeconds seconds (Attempt $_retryAttempts / $_maxRetries)');
            Future.delayed(Duration(seconds: delaySeconds), () {
              if (mounted) _loadAd();
            });
          }
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      // In release mode, we might want to return a smaller placeholder or nothing 
      // if it hasn't loaded yet to avoid large empty gaps.
      // But we keep the reserved space to avoid jumps once it loads.
      return SizedBox(
        width: widget.adSize.width.toDouble(),
        height: _isLoaded ? widget.adSize.height.toDouble() : 0, // Collapse if not loaded
        child: const SizedBox.shrink(),
      );
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
