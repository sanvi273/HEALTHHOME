package com.example.healthhome

import android.util.Log

class HealthHomeTgCalls {

    companion object {
        private const val TAG = "HealthHomeTgCalls"

        var loadError: String? = null

        init {
            try {
                System.loadLibrary("healthhome_tgcalls")
                Log.d(TAG, "Native library loaded successfully")
            } catch (e: Throwable) {
                loadError = e.toString()
                Log.e(TAG, "Native library loading failed", e)
            }
        }
    }

    external fun nativeTest(): String
}