package com.securescan.securescan

import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.WindowManager
import android.graphics.Color
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Full-screen overlay activity that shows after a call ends.
 * Uses Flutter's overlayMain entry point to render the overlay UI.
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
    
    private var appChannel: MethodChannel? = null
    private var overlayChannel: MethodChannel? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setupFullScreen()
        Log.d(TAG, "OverlayActivity created")
    }
    
    private fun setupFullScreen() {
        // Show over lock screen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        
        // Full screen setup
        window.apply {
            addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            statusBarColor = Color.WHITE
            navigationBarColor = Color.WHITE
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                setDecorFitsSystemWindows(true)
            }
            
            // Light status bar icons (dark icons on white background)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
            }
        }
    }
    
    override fun getDartEntrypointFunctionName(): String {
        return "overlayMain"
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        val phoneNumber = intent.getStringExtra(EXTRA_PHONE_NUMBER) ?: "Unknown Number"
        val callStatus = intent.getStringExtra(EXTRA_CALL_STATUS) ?: "ended"
        
        Log.d(TAG, "Configuring with number: $phoneNumber, status: $callStatus")
        
        // Setup app channel for navigation
        appChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.securescan.securescan/app")
        appChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "openApp" -> {
                    val route = call.argument<String>("route")
                    openMainApp(route)
                    result.success(true)
                }
                "finishOverlay" -> {
                    Log.d(TAG, "Finishing overlay activity")
                    finish()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        // Setup overlay channel for data
        overlayChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.securescan.securescan/overlay")
        
        // Send call data to Flutter after a short delay
        window.decorView.postDelayed({
            try {
                overlayChannel?.invokeMethod("setCallData", mapOf(
                    "number" to phoneNumber,
                    "status" to callStatus
                ))
                Log.d(TAG, "✅ Call data sent to Flutter")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to send call data: ${e.message}")
            }
        }, 300)
    }
    
    private fun openMainApp(route: String?) {
        try {
            Log.d(TAG, "Opening main app with route: $route")
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP
                route?.let { putExtra("route", it) }
            }
            startActivity(intent)
            finish() // Close overlay after launching main app
        } catch (e: Exception) {
            Log.e(TAG, "Error opening main app: ${e.message}")
        }
    }
    
    override fun onBackPressed() {
        // Close overlay on back press
        finish()
    }
}
