package com.securescan.securescan

import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.MethodChannel

object AppLauncher {
    fun launchMainApp(context: Context, route: String? = null) {
        val packageName = context.packageName
        val launchIntent = context.packageManager.getLaunchIntentForPackage(packageName)
        
        launchIntent?.let { intent ->
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            route?.let { intent.putExtra("route", it) }
            context.startActivity(intent)
        }
    }
}
