import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_helper.dart';

/// Handles eager ad loading to improve user experience.
class AdPreloadService {
  AdPreloadService._();

  static final AdPreloadService instance = AdPreloadService._();

  BannerAd? _dashboardBannerAd;
  bool _isDashboardLoading = false;

  /// Begin loading the dashboard banner if it is not already loaded.
  void preloadDashboardBanner() {
    if (_dashboardBannerAd != null || _isDashboardLoading) return;

    _isDashboardLoading = true;
    final banner = BannerAd(
      adUnitId: AdHelper.dashboardBannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.largeBanner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _dashboardBannerAd = ad as BannerAd;
          _isDashboardLoading = false;
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _dashboardBannerAd = null;
          _isDashboardLoading = false;
        },
      ),
    );

    banner.load();
  }

  /// Retrieve a preloaded dashboard banner, if one exists.
  ///
  /// The returned ad is removed from the cache so the caller can manage its
  /// lifecycle independently.
  BannerAd? takeDashboardBanner() {
    final banner = _dashboardBannerAd;
    _dashboardBannerAd = null;
    return banner;
  }
}
