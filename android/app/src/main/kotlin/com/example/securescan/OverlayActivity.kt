package com.securescan.securescan

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * Full-screen overlay activity that shows after a call ends.
 * This bypasses Android 12+ background service restrictions by launching
 * as an Activity instead of a Service.
 */
class OverlayActivity : FlutterActivity() {
    
    companion object {
        private const val TAG = "OverlayActivity"
        const val EXTRA_PHONE_NUMBER = "phone_number"
        const val EXTRA_CALL_STATUS = "call_status"
        
        fun launch(context: android.content.Context, phoneNumber: String?, status: String = "ended") {
            try {
                val intent = Intent(context, OverlayActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                            Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS
                    putExtra(EXTRA_PHONE_NUMBER, phoneNumber ?: "Unknown Number")
                    putExtra(EXTRA_CALL_STATUS, status)
                }
                context.startActivity(intent)
                Log.d(TAG, "✅ OverlayActivity launched for number: $phoneNumber")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to launch OverlayActivity: ${e.message}")
            }
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Make this activity show over lock screen and turn screen on
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        
        // Full screen flags
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        
        Log.d(TAG, "OverlayActivity created")
    }
    
    override fun getDartEntrypointFunctionName(): String {
        return "overlayMain"
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Send the call data to Flutter after engine is configured
        val phoneNumber = intent.getStringExtra(EXTRA_PHONE_NUMBER) ?: "Unknown Number"
        val callStatus = intent.getStringExtra(EXTRA_CALL_STATUS) ?: "ended"
        
        Log.d(TAG, "Configuring Flutter engine with number: $phoneNumber, status: $callStatus")
        
        // Use a method channel to pass data to the overlay
        val channel = io.flutter.plugin.common.MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.securescan.securescan/overlay"
        )
        
        // Delay slightly to ensure Flutter is ready
        window.decorView.postDelayed({
            try {
                channel.invokeMethod("setCallData", mapOf(
                    "number" to phoneNumber,
                    "status" to callStatus
                ))
                Log.d(TAG, "✅ Call data sent to Flutter")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to send call data: ${e.message}")
            }
        }, 500)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        
        val phoneNumber = intent.getStringExtra(EXTRA_PHONE_NUMBER)
        val callStatus = intent.getStringExtra(EXTRA_CALL_STATUS)
        Log.d(TAG, "onNewIntent: number=$phoneNumber, status=$callStatus")
    }
}
