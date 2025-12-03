import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  const AdHelper._();

  // Dashboard banner ad unit provided by product team.
  static const String _androidDashboardBannerAdUnitId =
      'ca-app-pub-2148868058414204/3020458775';

  static const String _iosDashboardBannerAdUnitId =
      'ca-app-pub-2148868058414204/3020458775';

  // Google-provided sample ad unit IDs for development builds.
  static const String _androidTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  static const String _iosTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716';

  static String get dashboardBannerAdUnitId {
    // Use the official test ad units while developing so the SDK always has
    // fill and avoids the "Ad failed to load : 3" error code. Release builds
    // continue to use the production inventory configured above.
    if (!kReleaseMode) {
      if (Platform.isAndroid) {
        return _androidTestBannerAdUnitId;
      }
      if (Platform.isIOS) {
        return _iosTestBannerAdUnitId;
      }
    }

    if (Platform.isAndroid) {
      return _androidDashboardBannerAdUnitId;
    }
    if (Platform.isIOS) {
      return _iosDashboardBannerAdUnitId;
    }
    throw UnsupportedError('Unsupported platform');
  }
}
