package com.example.direcao_financeira_mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AppBubbleBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> AppBubbleService.startIfEnabled(context)
        }
    }
}
