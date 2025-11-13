package com.attendancepro.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    private val channelName = "com.attendancepro/native_timezone"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "getLocalTimezone") {
                    val timeZoneId = TimeZone.getDefault().id
                    if (timeZoneId.isNullOrEmpty()) {
                        result.error(
                            "UNAVAILABLE",
                            "Timezone information is not available on this device",
                            null
                        )
                    } else {
                        result.success(timeZoneId)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
