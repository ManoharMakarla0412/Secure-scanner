package com.securescan.securescan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager

import android.util.Log // Import Log

class CallReceiver : BroadcastReceiver() {
    companion object {
        var savedNumber: String? = null
        var wasInCall: Boolean = false      // Track if we were in an actual call
        var wasOutgoingCall: Boolean = false // Track if it was an outgoing call
        var lastState: String? = null       // Track last state to detect transitions
        private const val TAG = "QRBarcodeCallReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
        val incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
        
        Log.d(TAG, "onReceive: action=$action, state=$state, incomingNumber=$incomingNumber, wasInCall=$wasInCall, wasOutgoingCall=$wasOutgoingCall, lastState=$lastState")

        // Case 1: Outgoing call initiated
        if (action == Intent.ACTION_NEW_OUTGOING_CALL) {
            savedNumber = intent.getStringExtra(Intent.EXTRA_PHONE_NUMBER)
            wasInCall = true
            wasOutgoingCall = true
            lastState = "OUTGOING"
            Log.d(TAG, "📞 Outgoing Call Initiated: $savedNumber")
            return
        }

        // Use saved outgoing number if incoming is null
        val number = incomingNumber ?: savedNumber

        when (state) {
            // Case 2: Incoming call ringing
            TelephonyManager.EXTRA_STATE_RINGING -> {
                Log.d(TAG, "📞 State: RINGING - Incoming call from: $number")
                wasInCall = true
                wasOutgoingCall = false
                if (number != null) savedNumber = number
                lastState = state
            }
            
            // Case 3: Call answered/active (both incoming and outgoing)
            TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                Log.d(TAG, "📞 State: OFFHOOK - Call answered/active")
                wasInCall = true
                lastState = state
            }
            
            // Case 4: Call ended - Show overlay for ALL valid scenarios
            TelephonyManager.EXTRA_STATE_IDLE -> {
                Log.d(TAG, "📞 State: IDLE - wasInCall=$wasInCall, wasOutgoingCall=$wasOutgoingCall, lastState=$lastState")
                
                /*
                 * Show overlay in these scenarios:
                 * 1. Incoming call answered then hung up: RINGING → OFFHOOK → IDLE
                 * 2. Incoming call rejected/missed: RINGING → IDLE
                 * 3. Outgoing call connected then hung up: OUTGOING → OFFHOOK → IDLE
                 * 4. Outgoing call not answered/busy/cancelled: OUTGOING → IDLE
                 */
                val shouldShowOverlay = wasInCall && (
                    lastState == TelephonyManager.EXTRA_STATE_OFFHOOK ||  // Call was active
                    lastState == TelephonyManager.EXTRA_STATE_RINGING ||  // Incoming was ringing
                    lastState == "OUTGOING"  // Outgoing call (even if not connected)
                )
                
                if (shouldShowOverlay) {
                    val displayNumber = number ?: savedNumber ?: "Unknown"
                    Log.d(TAG, "✅ Call ended - Showing Overlay for number: $displayNumber")
                    showOverlay(context, displayNumber, "ended")
                } else {
                    Log.d(TAG, "⚠️ Skipping overlay - no valid call state detected")
                }
                
                // Reset all state
                wasInCall = false
                wasOutgoingCall = false
                savedNumber = null
                lastState = state
            }
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
            Log.d(TAG, "✅ Broadcast sent to trigger overlay")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to send overlay broadcast: ${e.message}")
            e.printStackTrace()
        }
    }
}
