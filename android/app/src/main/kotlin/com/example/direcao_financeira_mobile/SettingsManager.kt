package com.example.direcao_financeira_mobile

import android.content.Context

object SettingsManager {
    private const val PREFS_NAME = "traffic_light_settings"
    private const val KEY_POSITION = "position"
    private const val KEY_OVERLAY_OFFSET_X = "overlay_offset_x"
    private const val KEY_OVERLAY_OFFSET_Y = "overlay_offset_y"
    private const val KEY_HAS_CUSTOM_POSITION = "overlay_has_custom_position"
    private const val KEY_THEME = "theme"
    private const val KEY_FONT_SIZE = "font_size"
    private const val KEY_OPACITY = "opacity"
    private const val KEY_DURATION = "duration"
    private const val KEY_COLOR_BLIND = "color_blind"
    private const val KEY_INDICATOR_R_KM = "indicator_r_km"
    private const val KEY_INDICATOR_R_HORA = "indicator_r_hora"
    private const val KEY_INDICATOR_LUCRO_H = "indicator_lucro_h"
    private const val KEY_INDICATOR_NOTA = "indicator_nota"
    private const val KEY_MONITORED_APPS = "monitored_apps"
    private const val KEY_GAIN_PER_KM_BAD = "gain_per_km_bad"
    private const val KEY_GAIN_PER_KM_GOOD = "gain_per_km_good"
    private const val KEY_GAIN_PER_HOUR_BAD = "gain_per_hour_bad"
    private const val KEY_GAIN_PER_HOUR_GOOD = "gain_per_hour_good"
    private const val KEY_PASSENGER_RATING_BAD = "passenger_rating_bad"
    private const val KEY_PASSENGER_RATING_GOOD = "passenger_rating_good"
    private const val KEY_PASSENGER_RATING_CUSTOMIZED = "passenger_rating_customized"
    private const val KEY_FUEL_PRICE_PER_LITER_CENTS = "fuel_price_per_liter_cents"
    private const val KEY_KM_PER_LITER = "km_per_liter"
    private const val KEY_GOOGLE_MAPS_API_KEY = "google_maps_api_key"
    private const val KEY_TRAFFIC_LIGHT_ACTIVE = "traffic_light_active"
    private const val KEY_JOURNEY_ACTIVE = "journey_active"

    var position: Int = 0
    var overlayOffsetX: Int = 0
    var overlayOffsetY: Int = 0
    var hasCustomPosition: Boolean = false
    var theme: Int = 1
    var fontSize: Float = 15f
    var opacity: Float = 100f
    var duration: Int = 10
    var colorBlind: Boolean = false
    var indicators: Map<String, Boolean> = mapOf(
        "R$/Km" to true,
        "R$/Hora" to true,
        "Lucro/H" to true,
        "Nota" to true
    )
    var monitoredApps: Map<String, Boolean> = mapOf(
        "Uber" to true,
        "99" to true,
        "inDrive" to true,
        "MoveSj" to true,
        "MeLevaSJ" to false,
        "GooglePhotos" to false,
    )
    var gainPerKmBad: Double = 1.57
    var gainPerKmGood: Double = 2.60
    var gainPerHourBad: Double = 19.67
    var gainPerHourGood: Double = 32.50
    var passengerRatingBad: Double = 4.6
    var passengerRatingGood: Double = 5.0
    var passengerRatingCustomized: Boolean = false
    var fuelPricePerLiterCents: Int = 0
    var kmPerLiter: Double = 0.0
    var googleMapsApiKey: String = ""
    var trafficLightActive: Boolean = false
    var journeyActive: Boolean = false

    fun initialize(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        position = prefs.getInt(KEY_POSITION, position)
        overlayOffsetX = prefs.getInt(KEY_OVERLAY_OFFSET_X, overlayOffsetX)
        overlayOffsetY = prefs.getInt(KEY_OVERLAY_OFFSET_Y, overlayOffsetY)
        hasCustomPosition = prefs.getBoolean(KEY_HAS_CUSTOM_POSITION, hasCustomPosition)
        theme = prefs.getInt(KEY_THEME, theme)
        fontSize = prefs.getFloat(KEY_FONT_SIZE, fontSize)
        opacity = prefs.getFloat(KEY_OPACITY, opacity)
        duration = prefs.getInt(KEY_DURATION, duration)
        colorBlind = prefs.getBoolean(KEY_COLOR_BLIND, colorBlind)
        indicators = mapOf(
            "R$/Km" to prefs.getBoolean(KEY_INDICATOR_R_KM, true),
            "R$/Hora" to prefs.getBoolean(KEY_INDICATOR_R_HORA, true),
            "Lucro/H" to prefs.getBoolean(KEY_INDICATOR_LUCRO_H, true),
            "Nota" to prefs.getBoolean(KEY_INDICATOR_NOTA, true),
        )
        val enabledMonitoredApps = prefs.getStringSet(KEY_MONITORED_APPS, null)
        if (enabledMonitoredApps != null) {
            monitoredApps =
                monitoredApps.mapValues { entry ->
                    enabledMonitoredApps.contains(entry.key)
                }
        }
        gainPerKmBad = prefs.getFloat(KEY_GAIN_PER_KM_BAD, gainPerKmBad.toFloat()).toDouble()
        gainPerKmGood = prefs.getFloat(KEY_GAIN_PER_KM_GOOD, gainPerKmGood.toFloat()).toDouble()
        gainPerHourBad =
            prefs.getFloat(KEY_GAIN_PER_HOUR_BAD, gainPerHourBad.toFloat()).toDouble()
        gainPerHourGood =
            prefs.getFloat(KEY_GAIN_PER_HOUR_GOOD, gainPerHourGood.toFloat()).toDouble()
        passengerRatingBad =
            prefs.getFloat(KEY_PASSENGER_RATING_BAD, passengerRatingBad.toFloat()).toDouble()
        passengerRatingGood =
            prefs.getFloat(KEY_PASSENGER_RATING_GOOD, passengerRatingGood.toFloat()).toDouble()
        passengerRatingCustomized =
            prefs.getBoolean(KEY_PASSENGER_RATING_CUSTOMIZED, passengerRatingCustomized)
        fuelPricePerLiterCents = prefs.getInt(KEY_FUEL_PRICE_PER_LITER_CENTS, fuelPricePerLiterCents)
        kmPerLiter = prefs.getFloat(KEY_KM_PER_LITER, kmPerLiter.toFloat()).toDouble()
        googleMapsApiKey = prefs.getString(KEY_GOOGLE_MAPS_API_KEY, googleMapsApiKey) ?: googleMapsApiKey
        trafficLightActive = prefs.getBoolean(KEY_TRAFFIC_LIGHT_ACTIVE, false)
        journeyActive = prefs.getBoolean(KEY_JOURNEY_ACTIVE, false)
    }

    fun update(context: Context, data: Map<String, Any>) {
        val newPosition = (data["position"] as? Int) ?: position
        if (newPosition != position) {
            overlayOffsetX = 0
            overlayOffsetY = 0
            hasCustomPosition = false
        }

        position = newPosition
        theme = (data["theme"] as? Int) ?: 1
        fontSize = (data["font_size"] as? Double)?.toFloat() ?: 15f
        opacity = (data["opacity"] as? Double)?.toFloat() ?: 100f
        duration = (data["duration"] as? Double)?.toInt() ?: 10
        colorBlind = (data["color_blind"] as? Boolean) ?: false
        
        val rawIndicators = (data["indicators"] as? Map<*, *>)
        if (rawIndicators != null) {
            indicators =
                rawIndicators.entries.associate { entry ->
                    entry.key.toString() to (entry.value == true)
                }
        }

        val rawMonitoredApps =
            (data["monitored_apps"] as? Map<*, *>) ?: (data["monitoredApps"] as? Map<*, *>)
        if (rawMonitoredApps != null) {
            monitoredApps =
                monitoredApps.keys.associateWith { appName ->
                    rawMonitoredApps[appName] == true
                }
        }
        gainPerKmBad = (data["gain_per_km_bad"] as? Number)?.toDouble() ?: gainPerKmBad
        gainPerKmGood = (data["gain_per_km_good"] as? Number)?.toDouble() ?: gainPerKmGood
        gainPerHourBad =
            (data["gain_per_hour_bad"] as? Number)?.toDouble() ?: gainPerHourBad
        gainPerHourGood =
            (data["gain_per_hour_good"] as? Number)?.toDouble() ?: gainPerHourGood
        passengerRatingBad =
            (data["passenger_rating_bad"] as? Number)?.toDouble() ?: passengerRatingBad
        passengerRatingGood =
            (data["passenger_rating_good"] as? Number)?.toDouble() ?: passengerRatingGood
        passengerRatingCustomized =
            (data["passenger_rating_customized"] as? Boolean) ?: passengerRatingCustomized
        fuelPricePerLiterCents =
            (data["fuel_price_per_liter_cents"] as? Number)?.toInt() ?: fuelPricePerLiterCents
        kmPerLiter = (data["km_per_liter"] as? Number)?.toDouble() ?: kmPerLiter
        googleMapsApiKey = (data["google_maps_api_key"] as? String)?.trim() ?: googleMapsApiKey

        persist(context)
    }

    fun updateOverlayOffset(
        context: Context,
        x: Int,
        y: Int,
    ) {
        overlayOffsetX = x
        overlayOffsetY = y
        hasCustomPosition = true
        persist(context)
    }

    fun updateRuntimeState(
        context: Context,
        trafficLightActive: Boolean? = null,
        journeyActive: Boolean? = null,
    ) {
        if (trafficLightActive != null) {
            this.trafficLightActive = trafficLightActive
        }

        if (journeyActive != null) {
            this.journeyActive = journeyActive
        }

        persist(context)
    }

    fun shouldKeepRuntimeActive(): Boolean {
        return trafficLightActive || journeyActive
    }

    fun shouldShowTrafficLight(): Boolean {
        return trafficLightActive
    }

    fun isMonitoredAppEnabled(appName: String): Boolean {
        return monitoredApps[appName] == true
    }

    private fun persist(context: Context) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putInt(KEY_POSITION, position)
            .putInt(KEY_OVERLAY_OFFSET_X, overlayOffsetX)
            .putInt(KEY_OVERLAY_OFFSET_Y, overlayOffsetY)
            .putBoolean(KEY_HAS_CUSTOM_POSITION, hasCustomPosition)
            .putInt(KEY_THEME, theme)
            .putFloat(KEY_FONT_SIZE, fontSize)
            .putFloat(KEY_OPACITY, opacity)
            .putInt(KEY_DURATION, duration)
            .putBoolean(KEY_COLOR_BLIND, colorBlind)
            .putBoolean(KEY_INDICATOR_R_KM, indicators["R$/Km"] == true)
            .putBoolean(KEY_INDICATOR_R_HORA, indicators["R$/Hora"] == true)
            .putBoolean(KEY_INDICATOR_LUCRO_H, indicators["Lucro/H"] == true)
            .putBoolean(KEY_INDICATOR_NOTA, indicators["Nota"] == true)
            .putStringSet(
                KEY_MONITORED_APPS,
                monitoredApps.filterValues { it }.keys.toSet(),
            )
            .putFloat(KEY_GAIN_PER_KM_BAD, gainPerKmBad.toFloat())
            .putFloat(KEY_GAIN_PER_KM_GOOD, gainPerKmGood.toFloat())
            .putFloat(KEY_GAIN_PER_HOUR_BAD, gainPerHourBad.toFloat())
            .putFloat(KEY_GAIN_PER_HOUR_GOOD, gainPerHourGood.toFloat())
            .putFloat(KEY_PASSENGER_RATING_BAD, passengerRatingBad.toFloat())
            .putFloat(KEY_PASSENGER_RATING_GOOD, passengerRatingGood.toFloat())
            .putBoolean(KEY_PASSENGER_RATING_CUSTOMIZED, passengerRatingCustomized)
            .putInt(KEY_FUEL_PRICE_PER_LITER_CENTS, fuelPricePerLiterCents)
            .putFloat(KEY_KM_PER_LITER, kmPerLiter.toFloat())
            .putString(KEY_GOOGLE_MAPS_API_KEY, googleMapsApiKey)
            .putBoolean(KEY_TRAFFIC_LIGHT_ACTIVE, trafficLightActive)
            .putBoolean(KEY_JOURNEY_ACTIVE, journeyActive)
            .apply()
    }
}
