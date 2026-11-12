package com.example.healthhome

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "healthhome_tgcalls"
    private val AV_PERMISSION_REQUEST = 9183
    private var pendingAvPermissionResult: MethodChannel.Result? = null
    private var incomingRingtone: Ringtone? = null
    private val ringtoneHandler = Handler(Looper.getMainLooper())
    private val ringtoneLoop = object : Runnable {
        override fun run() {
            val ringtone = incomingRingtone ?: return
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P && !ringtone.isPlaying) {
                ringtone.play()
            }
            if (incomingRingtone != null) ringtoneHandler.postDelayed(this, 500)
        }
    }

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

            } else if (call.method == "requestAvPermissions") {
                requestAvPermissions(result)
            } else if (call.method == "startIncomingRingtone") {
                startIncomingRingtone(result)
            } else if (call.method == "stopIncomingRingtone") {
                stopIncomingRingtone()
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun requestAvPermissions(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            result.success(true)
            return
        }
        val permissions = arrayOf(Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO)
        val missing = permissions.filter {
            checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isEmpty()) {
            result.success(true)
            return
        }
        if (pendingAvPermissionResult != null) {
            result.error("PERMISSION_REQUEST_ACTIVE", "A camera/microphone permission request is already active.", null)
            return
        }
        pendingAvPermissionResult = result
        requestPermissions(missing.toTypedArray(), AV_PERMISSION_REQUEST)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != AV_PERMISSION_REQUEST) return
        val granted = grantResults.isNotEmpty() && grantResults.all {
            it == PackageManager.PERMISSION_GRANTED
        } && checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED &&
            checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        pendingAvPermissionResult?.success(granted)
        pendingAvPermissionResult = null
    }

    private fun startIncomingRingtone(result: MethodChannel.Result) {
        try {
            stopIncomingRingtone()
            val uri = RingtoneManager.getActualDefaultRingtoneUri(
                applicationContext,
                RingtoneManager.TYPE_RINGTONE
            ) ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            if (uri == null) {
                result.error("RINGTONE_UNAVAILABLE", "No default phone ringtone is configured.", null)
                return
            }
            incomingRingtone = RingtoneManager.getRingtone(applicationContext, uri)
            incomingRingtone?.let { ringtone ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    ringtone.audioAttributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) ringtone.isLooping = true
                ringtone.play()
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
                    ringtoneHandler.postDelayed(ringtoneLoop, 500)
                }
            }
            if (incomingRingtone == null) {
                result.error("RINGTONE_UNAVAILABLE", "Android could not load the default phone ringtone.", null)
            } else {
                result.success(true)
            }
        } catch (error: Throwable) {
            stopIncomingRingtone()
            result.error("RINGTONE_ERROR", error.message, null)
        }
    }

    private fun stopIncomingRingtone() {
        ringtoneHandler.removeCallbacks(ringtoneLoop)
        try {
            incomingRingtone?.stop()
        } catch (_: Throwable) {
        } finally {
            incomingRingtone = null
        }
    }

    override fun onDestroy() {
        stopIncomingRingtone()
        super.onDestroy()
    }
}
