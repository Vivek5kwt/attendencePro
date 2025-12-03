import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  const AdHelper._();

  static const String _androidDashboardBannerAdUnitId =
      String.fromEnvironment('ANDROID_DASHBOARD_BANNER_AD_UNIT_ID',
          defaultValue: 'ca-app-pub-2148868058414204/3020458775');

  static const String _iosDashboardBannerAdUnitId =
      String.fromEnvironment('IOS_DASHBOARD_BANNER_AD_UNIT_ID',
          defaultValue: 'ca-app-pub-2148868058414204/3020458775');

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
