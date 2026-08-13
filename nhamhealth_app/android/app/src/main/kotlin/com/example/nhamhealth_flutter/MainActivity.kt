package com.example.nhamhealth_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            GOOGLE_OAUTH_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getServerClientId" -> result.success(BuildConfig.GOOGLE_SERVER_CLIENT_ID)
                else -> result.notImplemented()
            }
        }
    }

    private companion object {
        const val GOOGLE_OAUTH_CHANNEL =
            "com.example.nhamhealth_flutter/google_oauth_config"
    }
}
