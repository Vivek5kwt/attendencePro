import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/localization/app_localizations.dart';
import '../utils/ad_helper.dart';
import '../utils/ad_preload_service.dart';

class DashboardBannerAd extends StatefulWidget {
  const DashboardBannerAd({super.key, required this.localization});

  final AppLocalizations localization;

  @override
  State<DashboardBannerAd> createState() => _DashboardBannerAdState();
}

class _DashboardBannerAdState extends State<DashboardBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _usePreloadedAdOrLoad();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _usePreloadedAdOrLoad() {
    final preloaded = AdPreloadService.instance.takeDashboardBanner();
    if (preloaded != null) {
      _bannerAd = preloaded;
      _isLoaded = true;
      return;
    }

    _loadAd();
  }

  void _loadAd() {
    final banner = BannerAd(
      adUnitId: AdHelper.dashboardBannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.largeBanner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });
        },
      ),
    );

    banner.load();
    _bannerAd = banner;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final banner = _bannerAd;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F9FF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE0EDFF)),
        ),
        padding: const EdgeInsets.all(20),
        child: _isLoaded && banner != null
            ? Center(
                child: SizedBox(
                  width: banner.size.width.toDouble(),
                  height: banner.size.height.toDouble(),
                  child: AdWidget(ad: banner),
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0EDFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.ads_click_outlined,
                      color: Color(0xFF1D4ED8),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.localization.adPlaceholderTitle,
                          style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                                fontSize: 18,
                              ) ??
                              const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                                fontSize: 18,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.localization.adPlaceholderSubtitle,
                          style: textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF4B5563),
                                height: 1.4,
                              ) ??
                              const TextStyle(
                                color: Color(0xFF4B5563),
                                height: 1.4,
                                fontSize: 14,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
