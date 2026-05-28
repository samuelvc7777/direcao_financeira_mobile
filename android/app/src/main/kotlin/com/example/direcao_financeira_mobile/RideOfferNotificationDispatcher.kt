package com.example.direcao_financeira_mobile

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

class RideOfferNotificationDispatcher(
    private val context: Context,
) {
    private var lastNotificationId: Int? = null

    fun show(data: Map<String, Any>): Boolean {
        if (!canPostNotifications()) {
            debugLog("ride_offer_notification_permission_denied")
            return false
        }

        val content = RideOfferNotificationFormatter.format(data)
        createNotificationChannel()

        val builder =
            NotificationCompat.Builder(context, notificationChannelId)
                .setSmallIcon(android.R.drawable.ic_dialog_map)
                .setContentTitle(content.title)
                .setContentText(content.contentText)
                .setSubText(content.summaryText)
                .setStyle(
                    NotificationCompat.InboxStyle()
                        .setBigContentTitle(content.expandedTitle)
                        .setSummaryText(content.summaryText)
                        .also { style ->
                            content.inboxLines.forEach(style::addLine)
                        },
                )
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_STATUS)
                .setAutoCancel(true)
                .setWhen(System.currentTimeMillis())
                .setShowWhen(true)
                .setContentIntent(buildLaunchAppPendingIntent(content.notificationId))

        if (content.hasOriginAction) {
            builder.addAction(
                android.R.drawable.ic_dialog_map,
                "Abrir origem",
                buildMapsPendingIntent(
                    address = content.originAddress!!,
                    requestCode = content.notificationId + 1,
                ),
            )
        }

        if (content.hasDestinationAction) {
            builder.addAction(
                android.R.drawable.ic_dialog_map,
                "Abrir destino",
                buildMapsPendingIntent(
                    address = content.destinationAddress!!,
                    requestCode = content.notificationId + 2,
                ),
            )
        }

        return runCatching {
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(content.notificationId, builder.build())
            lastNotificationId = content.notificationId
            true
        }.getOrElse { error ->
            debugLog("ride_offer_notification_failure message=${error.message}")
            false
        }
    }

    fun dismissLast() {
        val notificationId = lastNotificationId ?: return
        runCatching {
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(notificationId)
            lastNotificationId = null
        }.onFailure { error ->
            debugLog("ride_offer_notification_cancel_failure message=${error.message}")
        }
    }

    private fun canPostNotifications(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return true
        }

        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel =
            NotificationChannel(
                notificationChannelId,
                "Corridas detectadas",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Notificacoes de corridas detectadas com atalhos para o Maps."
                setShowBadge(true)
            }

        notificationManager.createNotificationChannel(channel)
    }

    private fun buildLaunchAppPendingIntent(notificationId: Int): PendingIntent? {
        val launchIntent =
            context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            } ?: return null

        return PendingIntent.getActivity(
            context,
            notificationId,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentImmutableFlag(),
        )
    }

    private fun buildMapsPendingIntent(
        address: String,
        requestCode: Int,
    ): PendingIntent {
        return PendingIntent.getActivity(
            context,
            requestCode,
            buildMapsIntent(address),
            PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentImmutableFlag(),
        )
    }

    private fun buildMapsIntent(address: String): Intent {
        val encodedAddress = Uri.encode(address)
        val uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$encodedAddress")
        val mapsIntent =
            Intent(Intent.ACTION_VIEW, uri).apply {
                setPackage(googleMapsPackage)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

        if (mapsIntent.resolveActivity(context.packageManager) != null) {
            return mapsIntent
        }

        return Intent(Intent.ACTION_VIEW, uri).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    }

    private fun pendingIntentImmutableFlag(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
    }

    private fun debugLog(message: String) {
        if ((context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
            Log.d(logTag, message)
        }
    }

    private companion object {
        const val notificationChannelId = "corridas_detectadas"
        const val googleMapsPackage = "com.google.android.apps.maps"
        const val logTag = "DF-RideNotification"
    }
}
