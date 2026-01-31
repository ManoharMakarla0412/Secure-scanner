package com.securescan.securescan

import android.content.Context
import android.content.Intent
import android.content.BroadcastReceiver
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.IntentFilter
import android.telephony.TelephonyManager
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.securescan.securescan/app"
    private val TAG = "SecureScanMainActivity"
    private var callReceiver: CallReceiver? = null
    private var overlayBroadcastReceiver: BroadcastReceiver? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "registerCallReceiver" -> {
                    registerCallReceiver()
                    result.success(true)
                }
                "openApp" -> {
                    val route = call.argument<String>("route")
                    openApp(route)
                    result.success(true)
                }
                "showOverlay" -> {
                    val status = call.argument<String>("status") ?: "ended"
                    val number = call.argument<String>("number") ?: "Unknown"
                    Log.d(TAG, "showOverlay called from Flutter: status=$status, number=$number")
                    // This will be handled by CallManager in Flutter
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        // Register overlay broadcast receiver
        registerOverlayReceiver()
    }

    override fun getInitialRoute(): String? {
        return intent.getStringExtra("route") ?: super.getInitialRoute()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        try {
            val route = intent.getStringExtra("route")
             android.util.Log.d("StartApp", "onNewIntent received route: $route")
            if (route != null) {
                flutterEngine?.navigationChannel?.pushRoute(route)
            }
        } catch (e: Exception) {
             android.util.Log.e("StartApp", "Error in onNewIntent: ${e.message}")
        }
    }

    private fun openApp(route: String?) {
        try {
             android.util.Log.d("StartApp", "openApp called with route: $route")
            val intent = Intent(this, MainActivity::class.java).apply {
                // REORDER_TO_FRONT brings the activity to top without killing it
                flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP
                route?.let { putExtra("route", it) }
            }
            startActivity(intent)
        } catch (e: Exception) {
             android.util.Log.e("StartApp", "Error in openApp: ${e.message}")
        }
    }
    
    private fun registerCallReceiver() {
        try {
            if (callReceiver == null) {
                callReceiver = CallReceiver()
                val filter = IntentFilter().apply {
                    addAction(TelephonyManager.ACTION_PHONE_STATE_CHANGED)
                    addAction(Intent.ACTION_NEW_OUTGOING_CALL)
                }
                registerReceiver(callReceiver, filter)
                Log.d(TAG, "✅ CallReceiver registered dynamically")
            } else {
                Log.d(TAG, "CallReceiver already registered")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to register CallReceiver: ${e.message}")
        }
    }
    
    private fun registerOverlayReceiver() {
        try {
            if (overlayBroadcastReceiver == null) {
                overlayBroadcastReceiver = object : BroadcastReceiver() {
                    override fun onReceive(context: Context, intent: Intent) {
                        val status = intent.getStringExtra("status") ?: "ended"
                        val number = intent.getStringExtra("number") ?: "Unknown"
                        Log.d(TAG, "Overlay broadcast received: status=$status, number=$number")
                        
                        // Invoke Flutter method to show overlay
                        methodChannel?.invokeMethod("triggerOverlay", mapOf(
                            "status" to status,
                            "number" to number
                        ))
                    }
                }
                val filter = IntentFilter("com.securescan.securescan.SHOW_OVERLAY")
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
                    registerReceiver(overlayBroadcastReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
                } else {
                    registerReceiver(overlayBroadcastReceiver, filter)
                }
                Log.d(TAG, "✅ OverlayBroadcastReceiver registered")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to register OverlayBroadcastReceiver: ${e.message}")
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        try {
            callReceiver?.let {
                unregisterReceiver(it)
                callReceiver = null
                Log.d(TAG, "CallReceiver unregistered")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering CallReceiver: ${e.message}")
        }
        
        try {
            overlayBroadcastReceiver?.let {
                unregisterReceiver(it)
                overlayBroadcastReceiver = null
                Log.d(TAG, "OverlayBroadcastReceiver unregistered")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering OverlayBroadcastReceiver: ${e.message}")
        }
    }
}
