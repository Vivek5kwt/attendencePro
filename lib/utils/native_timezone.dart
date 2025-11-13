import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FlutterNativeTimezone {
  const FlutterNativeTimezone._();

  static const MethodChannel _channel =
      MethodChannel('com.attendancepro/native_timezone');

  static Future<String> getLocalTimezone() async {
    if (!_supportsNativeChannel) {
      return _fallbackTimezone();
    }

    try {
      final String? timezone =
          await _channel.invokeMethod<String>('getLocalTimezone');
      if (timezone != null && timezone.isNotEmpty) {
        return timezone;
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to obtain native timezone: $error');
      debugPrint('$stackTrace');
    }

    return _fallbackTimezone();
  }

  static bool get _supportsNativeChannel {
    if (kIsWeb) {
      return false;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }

  static String _fallbackTimezone() {
    final name = DateTime.now().timeZoneName;
    if (name.isEmpty) {
      return 'UTC';
    }
    return name;
  }
}
