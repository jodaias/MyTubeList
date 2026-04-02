import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;

  static const _androidTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const _iosTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716';

  static const _androidReleaseBannerAdUnitId =
      String.fromEnvironment('ADMOB_ANDROID_BANNER_AD_UNIT_ID');
  static const _iosReleaseBannerAdUnitId =
      String.fromEnvironment('ADMOB_IOS_BANNER_AD_UNIT_ID');

  String get _adUnitId {
    if (kIsWeb) return '';

    if (kReleaseMode) {
      if (defaultTargetPlatform == TargetPlatform.android &&
          _androidReleaseBannerAdUnitId.isNotEmpty) {
        return _androidReleaseBannerAdUnitId;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          _iosReleaseBannerAdUnitId.isNotEmpty) {
        return _iosReleaseBannerAdUnitId;
      }
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidTestBannerAdUnitId;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosTestBannerAdUnitId;
    }

    return '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (_bannerAd != null || _isLoading || kIsWeb || !isMobile) {
      return;
    }

    _isLoading = true;

    final adSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.sizeOf(context).width.truncate(),
    );

    if (adSize == null || _adUnitId.isEmpty) {
      _isLoading = false;
      return;
    }

    final banner = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: adSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _isLoaded = true;
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isLoading = false;
        },
      ),
    );

    await banner.load();
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    final banner = _bannerAd;
    if (!_isLoaded || banner == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        width: banner.size.width.toDouble(),
        height: banner.size.height.toDouble(),
        child: AdWidget(ad: banner),
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}
