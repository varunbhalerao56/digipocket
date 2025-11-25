package com.vtbh.chuckit

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.vtbh.chuckit.sharing"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getAppGroupPath") {
                // On Android, we map "App Group Path" to the internal files directory
                // So Dart's Directory('$groupPath/share_queue') works automatically.
                result.success(context.filesDir.absolutePath)
            } else {
                result.notImplemented()
            }
        }
    }
}