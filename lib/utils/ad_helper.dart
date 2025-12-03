import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  const AdHelper._();

  // Dashboard banner ad unit provided by product team.
  static const String _androidDashboardBannerAdUnitId =
      'ca-app-pub-2148868058414204/3020458775';

  static const String _iosDashboardBannerAdUnitId =
      'ca-app-pub-2148868058414204/3020458775';

  static String get dashboardBannerAdUnitId {
    if (Platform.isAndroid) {
      return _androidDashboardBannerAdUnitId;
    }
    if (Platform.isIOS) {
      return _iosDashboardBannerAdUnitId;
    }
    throw UnsupportedError('Unsupported platform');
  }
}
