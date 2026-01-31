package com.securescan.securescan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager

import android.util.Log // Import Log

class CallReceiver : BroadcastReceiver() {
    companion object {
        var savedNumber: String? = null
        var wasInCall: Boolean = false  // Track if we were in an actual call
        var lastState: String? = null   // Track last state to detect transitions
        private const val TAG = "SecureScanCallReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
        val incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
        
        Log.d(TAG, "onReceive: action=$action, state=$state, incomingNumber=$incomingNumber, wasInCall=$wasInCall, lastState=$lastState")

        if (action == Intent.ACTION_NEW_OUTGOING_CALL) {
            savedNumber = intent.getStringExtra(Intent.EXTRA_PHONE_NUMBER)
            Log.d(TAG, "Outgoing Call Saved: $savedNumber")
            return
        }

        // Use saved outgoing number if incoming is null (logic for outgoing)
        val number = incomingNumber ?: savedNumber

        if (state == TelephonyManager.EXTRA_STATE_RINGING) {
             Log.d(TAG, "State: RINGING")
             // Capture incoming number if needed, but don't show overlay yet
             // showOverlay(context, number, "incoming")
        } else if (state == TelephonyManager.EXTRA_STATE_OFFHOOK) {
             Log.d(TAG, "State: OFFHOOK")
             // Active call - don't show overlay yet
             // showOverlay(context, number, "active")
        } else if (state == TelephonyManager.EXTRA_STATE_IDLE) {
             Log.d(TAG, "State: IDLE (Ended) - Showing Overlay")
             showOverlay(context, number, "ended")
             savedNumber = null // Reset
        }
    }

    private fun showOverlay(context: Context, number: String?, status: String) {
        try {
            Log.d(TAG, "Attempting to show overlay for status: $status, number: $number")
            
            // Send broadcast to MainActivity to trigger overlay via Flutter method channel
            val broadcastIntent = Intent("com.securescan.securescan.SHOW_OVERLAY").apply {
                setPackage(context.packageName)
                putExtra("status", status)
                putExtra("number", number ?: "Unknown")
            }
            context.sendBroadcast(broadcastIntent)
            Log.d(TAG, "Broadcast sent to trigger overlay")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to send overlay broadcast: ${e.message}")
            e.printStackTrace()
        }
    }
}
