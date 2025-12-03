import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  const AdHelper._();

  static const String _androidDashboardBannerAdUnitId =
      String.fromEnvironment('ANDROID_DASHBOARD_BANNER_AD_UNIT_ID',
          defaultValue: 'ca-app-pub-3940256099942544/6300978111');

  static const String _iosDashboardBannerAdUnitId =
      String.fromEnvironment('IOS_DASHBOARD_BANNER_AD_UNIT_ID',
          defaultValue: 'ca-app-pub-3940256099942544/2934735716');

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
