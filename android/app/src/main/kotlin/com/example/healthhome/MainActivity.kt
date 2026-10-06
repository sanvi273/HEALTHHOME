package com.example.healthhome

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "healthhome_tgcalls"

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            if (call.method == "testNative") {

                try {
                    val loadError =
                        HealthHomeTgCalls.loadError

                    if (loadError != null) {
                        result.error(
                            "NATIVE_LIBRARY_ERROR",
                            loadError,
                            null
                        )
                        return@setMethodCallHandler
                    }

                    val native =
                        HealthHomeTgCalls()

                    val message =
                        native.nativeTest()

                    result.success(message)

                } catch (e: Throwable) {

                    result.error(
                        "NATIVE_BRIDGE_ERROR",
                        e.toString(),
                        null
                    )
                }

            } else {
                result.notImplemented()
            }
        }
    }
}