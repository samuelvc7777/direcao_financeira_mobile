package com.example.direcao_financeira_mobile

import android.content.Context
import android.content.Intent
import android.net.Uri

object MapsIntentFactory {
    private const val googleMapsPackage = "com.google.android.apps.maps"

    fun buildSearchIntent(
        context: Context,
        address: String,
    ): Intent {
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
}
