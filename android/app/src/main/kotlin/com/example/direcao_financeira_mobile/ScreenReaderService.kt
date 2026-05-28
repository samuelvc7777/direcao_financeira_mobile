package com.example.direcao_financeira_mobile

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityService.TakeScreenshotCallback
import android.app.KeyguardManager
import android.content.Context
import android.content.pm.ApplicationInfo
import android.graphics.Bitmap
import android.graphics.ColorSpace
import android.hardware.HardwareBuffer
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.Display
import android.view.accessibility.AccessibilityEvent
import com.example.direcao_financeira_mobile.parsers.MeLevaSjParser
import com.example.direcao_financeira_mobile.parsers.MoveSjParser
import com.example.direcao_financeira_mobile.parsers.NinetyNineOcrParser
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.plugin.common.MethodChannel
import java.net.HttpURLConnection
import java.net.URL
import org.json.JSONArray
import org.json.JSONObject
import java.text.Normalizer

class ScreenReaderService : AccessibilityService() {
    private val logTag = "DF-MoveSjDebug"
    private val lockLogPrefix = "LOCK_DEBUG"
    private val ninetyNineDriverPackages =
        setOf(
            "com.app99.driver",
            "com.nineninetaxis.driver",
            "com.taxis99.driver",
            "com.taxis99",
        )
    private val moveSjDriverPackage = "br.com.devbase.movesj.prestador"
    private val meLevaSjDriverPackage = "br.com.melevasj.taxi.drivermachine"
    private val googlePhotosPackage = "com.google.android.apps.photos"
    private val minimumProcessingIntervalMs = 350L
    private val minimumOcrIntervalMs = 3000L
    private val minimumMoveSjOcrIntervalMs = 2000L
    private val ninetyNineReadDelayMs = 300L
    private val moveSjReadDelayMs = 450L
    private val moveSjRetryDelayMs = 650L
    private val maxMoveSjOcrAttempts = 2
    private val ocrWatchdogTimeoutMs = 8000L
    private val overlayDisplayDelayMs = 200L
    private val repeatedOfferQuietWindowMs = 2500L
    private val duplicateOfferWindowMs = 20000L

    private val moveSjParser = MoveSjParser()
    private val meLevaSjParser = MeLevaSjParser()
    private val ninetyNineOcrParser = NinetyNineOcrParser()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var floatingOverlay: FloatingOverlay? = null
    private var rideOfferNotificationDispatcher: RideOfferNotificationDispatcher? = null
    private var lastOfferData: Map<String, Any>? = null
    private var lastProcessedPackage: String? = null
    private var lastProcessedAtElapsed = 0L
    private var lastOcrAtElapsed = 0L
    private var lastAcceptedOfferAtElapsed = 0L
    private var lastAcceptedOfferSignature = ""
    private var lastAcceptedMoveSjCoreSignature = ""
    private var lastAcceptedPassengerRouteSignature = ""
    private var ocrInFlight = false
    private var activeOcrToken = 0
    private var ocrWatchdogRunnable: Runnable? = null
    private var pendingNinetyNineRunnable: Runnable? = null
    private var pendingMoveSjRunnable: Runnable? = null
    private var pendingOverlayRunnable: Runnable? = null

    companion object {
        private const val pendingDetectedRidesPrefs = "df_pending_detected_rides"
        private const val pendingDetectedRidesKey = "items"
        private const val pendingDetectedRidesLimit = 200
        private var channel: MethodChannel? = null

        fun setMethodChannel(methodChannel: MethodChannel) {
            channel = methodChannel
        }

        fun consumePendingDetectedRides(context: Context): List<Map<String, Any?>> {
            val prefs =
                context.applicationContext.getSharedPreferences(
                    pendingDetectedRidesPrefs,
                    Context.MODE_PRIVATE,
                )
            val raw = prefs.getString(pendingDetectedRidesKey, null) ?: return emptyList()
            val items =
                runCatching {
                    val array = JSONArray(raw)
                    buildList {
                        for (index in 0 until array.length()) {
                            val json = array.optJSONObject(index) ?: continue
                            add(jsonObjectToMap(json))
                        }
                    }
                }.getOrDefault(emptyList())

            prefs.edit().remove(pendingDetectedRidesKey).apply()
            return items
        }

        private fun enqueuePendingDetectedRide(
            context: Context,
            data: Map<String, Any>,
        ) {
            val appContext = context.applicationContext
            val prefs =
                appContext.getSharedPreferences(
                    pendingDetectedRidesPrefs,
                    Context.MODE_PRIVATE,
                )
            val current =
                runCatching {
                    JSONArray(prefs.getString(pendingDetectedRidesKey, "[]"))
                }.getOrDefault(JSONArray())

            current.put(mapToJsonObject(data))

            while (current.length() > pendingDetectedRidesLimit) {
                current.remove(0)
            }

            prefs.edit().putString(pendingDetectedRidesKey, current.toString()).apply()
        }

        private fun mapToJsonObject(data: Map<String, Any>): JSONObject {
            val json = JSONObject()
            data.forEach { (key, value) ->
                json.put(key, value)
            }
            return json
        }

        private fun jsonObjectToMap(json: JSONObject): Map<String, Any?> =
            buildMap {
                val keys = json.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    val value = json.opt(key)
                    put(key, if (value == JSONObject.NULL) null else value)
                }
            }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        SettingsManager.initialize(this)
        floatingOverlay = FloatingOverlay(this)
        rideOfferNotificationDispatcher = RideOfferNotificationDispatcher(this)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        logLockscreenEvent("event_received", event = event)

        if (!SettingsManager.shouldKeepRuntimeActive()) {
            pendingOverlayRunnable?.let(mainHandler::removeCallbacks)
            pendingMoveSjRunnable?.let(mainHandler::removeCallbacks)
            pendingNinetyNineRunnable?.let(mainHandler::removeCallbacks)
            ocrWatchdogRunnable?.let(mainHandler::removeCallbacks)
            pendingOverlayRunnable = null
            pendingMoveSjRunnable = null
            pendingNinetyNineRunnable = null
            ocrWatchdogRunnable = null
            ocrInFlight = false
            floatingOverlay?.hide()
            restoreAppBubbleAfterRideOffer()
            lastOfferData = null
            logLockscreenMessage("runtime_inactive_skip")
            return
        }

        if (!SettingsManager.shouldShowTrafficLight()) {
            restoreAppBubbleAfterRideOffer()
            logLockscreenMessage("traffic_light_disabled_skip")
            return
        }

        val packageName = event.packageName?.toString()
        if (
            packageName.isNullOrBlank() ||
                !isSupportedRidePackage(packageName) ||
                !isRelevantMonitoredPackage(packageName)
        ) {
            restoreAppBubbleAfterRideOffer()
            logLockscreenEvent(
                "package_filtered",
                event = event,
                extra =
                    mapOf(
                        "isSupportedRidePackage" to (!packageName.isNullOrBlank() && isSupportedRidePackage(packageName)),
                        "isRelevantMonitoredPackage" to (!packageName.isNullOrBlank() && isRelevantMonitoredPackage(packageName)),
                    ),
            )
            return
        }

        if (shouldThrottle(packageName) || shouldRespectQuietWindow(packageName)) {
            logLockscreenEvent(
                "throttled_or_quiet_window",
                event = event,
                extra =
                    mapOf(
                        "shouldThrottle" to shouldThrottle(packageName),
                        "shouldRespectQuietWindow" to shouldRespectQuietWindow(packageName),
                    ),
            )
            return
        }

        if (isNinetyNineContext(packageName)) {
            logLockscreenEvent("schedule_99_processing", event = event)
            scheduleNinetyNineProcessing(packageName, event.displayId)
            return
        }

        val sourceAppKey =
            when (packageName) {
                moveSjDriverPackage -> "MoveSj"
                meLevaSjDriverPackage, googlePhotosPackage -> "MeLevaSJ"
                else -> "MoveSj"
            }

        logLockscreenEvent(
            "movesj_schedule_ocr_processing",
            event = event,
            extra = mapOf("sourceAppKey" to sourceAppKey),
        )
        scheduleMoveSjOcrProcessing(event.displayId, sourceAppKey = sourceAppKey)
    }

    private fun scheduleMoveSjOcrProcessing(
        displayId: Int,
        attempt: Int = 1,
        sourceAppKey: String = "MoveSj",
    ) {
        pendingMoveSjRunnable?.let(mainHandler::removeCallbacks)

        val safeAttempt = attempt.coerceIn(1, maxMoveSjOcrAttempts)
        val delayMs = if (safeAttempt == 1) moveSjReadDelayMs else moveSjRetryDelayMs
        val runnable =
            Runnable {
                pendingMoveSjRunnable = null
                logLockscreenMessage(
                    "movesj_ocr_delayed_processing",
                    extra =
                        mapOf(
                        "displayId" to displayId,
                        "attempt" to safeAttempt,
                        "sourceAppKey" to sourceAppKey,
                    ),
                )
                requestMoveSjOcr(displayId, safeAttempt, sourceAppKey)
            }

        pendingMoveSjRunnable = runnable
        mainHandler.postDelayed(runnable, delayMs)
    }

    private fun scheduleNinetyNineProcessing(
        packageName: String,
        displayId: Int,
    ) {
        pendingNinetyNineRunnable?.let(mainHandler::removeCallbacks)

        val runnable =
            Runnable {
                pendingNinetyNineRunnable = null
                logLockscreenMessage(
                    "99_ocr_delayed_processing",
                    extra =
                        mapOf(
                            "eventPackage" to packageName,
                            "displayId" to displayId,
                        ),
                )
                requestNinetyNineOcr(displayId)
            }

        pendingNinetyNineRunnable = runnable
        mainHandler.postDelayed(runnable, ninetyNineReadDelayMs)
    }

    private fun processOffer(offerData: Map<String, Any>) {
        if (offerData.isEmpty()) {
            logLockscreenMessage("process_offer_empty_payload")
            return
        }
        if (!SettingsManager.shouldShowTrafficLight()) {
            logLockscreenMessage("process_offer_traffic_light_disabled")
            return
        }
        if (!isMeaningfulOffer(offerData)) {
            logLockscreenMessage("process_offer_not_meaningful", extra = offerLogSummary(offerData))
            return
        }

        val signature = buildOfferSignature(offerData)
        val appKey = resolveOfferAppKey(offerData)
        if (appKey == "MoveSj" && !hasValidPassengerName(offerData)) {
            logLockscreenMessage("process_offer_invalid_passenger", extra = offerLogSummary(offerData))
            return
        }

        val moveSjCoreSignature = buildMoveSjCoreSignature(offerData)
        val passengerRouteSignature = buildPassengerRouteSignature(offerData)
        debugLog("MoveSj processOffer signature=$signature summary=${offerLogSummary(offerData)}")
        if (
            isDuplicateOffer(signature) ||
                isDuplicatePassengerRouteOffer(passengerRouteSignature) ||
                (appKey == "MoveSj" && isDuplicateMoveSjCoreOffer(moveSjCoreSignature))
        ) {
            debugLog("MoveSj oferta ignorada por assinatura duplicada.")
            logLockscreenMessage("process_offer_duplicate_signature", extra = offerLogSummary(offerData))
            return
        }

        val detectedOfferData =
            offerData + mapOf("detected_at_epoch_ms" to System.currentTimeMillis())

        lastOfferData = detectedOfferData
        lastAcceptedOfferSignature = signature
        if (appKey == "MoveSj") {
            lastAcceptedMoveSjCoreSignature = moveSjCoreSignature
        }
        lastAcceptedPassengerRouteSignature = passengerRouteSignature
        lastAcceptedOfferAtElapsed = SystemClock.elapsedRealtime()
        hideAppBubbleForRideOffer()

        pendingOverlayRunnable?.let(mainHandler::removeCallbacks)
        pendingOverlayRunnable =
            Runnable {
                logLockscreenMessage("overlay_show_attempt", extra = offerLogSummary(offerData))
                runCatching {
                    floatingOverlay?.show(offerData)
                }.onFailure { error ->
                    logLockscreenMessage(
                        "overlay_show_failure",
                        extra = mapOf("message" to (error.message ?: error::class.java.simpleName)),
                    )
                }
                pendingOverlayRunnable = null
            }.also { runnable ->
                mainHandler.postDelayed(runnable, overlayDisplayDelayMs)
            }

        rideOfferNotificationDispatcher?.show(detectedOfferData)
        notifyFlutter(detectedOfferData)
    }

    private fun offerLogSummary(offerData: Map<String, Any>): Map<String, Any?> {
        return mapOf(
            "app" to (offerData["platform_name"] ?: offerData["app"]),
            "valor" to offerData["valor_bruto"],
            "km" to offerData["km_total"],
            "min" to offerData["minutos_total"],
        )
    }

    private fun isSupportedRidePackage(packageName: String): Boolean {
        return isNinetyNineContext(packageName) ||
            packageName == moveSjDriverPackage ||
            packageName == meLevaSjDriverPackage ||
            packageName == googlePhotosPackage
    }

    private fun isNinetyNinePackage(packageName: String): Boolean {
        return ninetyNineDriverPackages.contains(packageName)
    }

    private fun isNinetyNineContext(packageName: String): Boolean {
        return isNinetyNinePackage(packageName)
    }

    private fun isRelevantMonitoredPackage(packageName: String): Boolean {
        return when {
            packageName == moveSjDriverPackage -> SettingsManager.isMonitoredAppEnabled("MoveSj")
            packageName == meLevaSjDriverPackage -> SettingsManager.isMonitoredAppEnabled("MeLevaSJ")
            packageName == googlePhotosPackage -> SettingsManager.isMonitoredAppEnabled("GooglePhotos")
            isNinetyNineContext(packageName) -> SettingsManager.isMonitoredAppEnabled("99")
            else -> false
        }
    }

    private fun shouldThrottle(packageName: String): Boolean {
        val now = SystemClock.elapsedRealtime()
        val shouldSkip =
            packageName == lastProcessedPackage &&
                now - lastProcessedAtElapsed < minimumProcessingIntervalMs

        if (!shouldSkip) {
            lastProcessedPackage = packageName
            lastProcessedAtElapsed = now
        }

        return shouldSkip
    }

    private fun shouldRespectQuietWindow(packageName: String): Boolean {
        if (lastAcceptedOfferAtElapsed == 0L) {
            return false
        }

        val currentApp = resolveAppKey(packageName) ?: return false
        val lastApp =
            lastOfferData?.get("platform_name")?.toString()?.takeIf { it.isNotBlank() }
                ?: lastOfferData?.get("app")?.toString()?.takeIf { it.isNotBlank() }
                ?: return false
        if (currentApp != lastApp) {
            return false
        }

        return SystemClock.elapsedRealtime() - lastAcceptedOfferAtElapsed <
            repeatedOfferQuietWindowMs
    }

    private fun isMeaningfulOffer(offerData: Map<String, Any>): Boolean {
        val priceText = offerData["valor_bruto"]?.toString().orEmpty()
        val priceValue =
            priceText.replace(Regex("[^0-9,]"), "")
                .replace(",", ".")
                .toDoubleOrNull() ?: 0.0
        val kmTotal = (offerData["km_total"] as? Number)?.toDouble() ?: 0.0
        val minTotal = (offerData["minutos_total"] as? Number)?.toInt() ?: 0

        return priceValue > 0.0 && (kmTotal > 0.0 || minTotal > 0)
    }

    private fun buildOfferSignature(offerData: Map<String, Any>?): String {
        if (offerData == null) {
            return ""
        }

        return listOf(
            offerData["app"]?.toString().orEmpty(),
            offerData["valor_bruto"]?.toString().orEmpty(),
            offerData["km_total"]?.toString().orEmpty(),
            offerData["minutos_total"]?.toString().orEmpty(),
            offerData["passenger_name"]?.toString().orEmpty(),
            offerData["origin_address"]?.toString().orEmpty(),
            offerData["destination_address"]?.toString().orEmpty(),
        ).joinToString("|")
    }

    private fun isDuplicateOffer(signature: String): Boolean {
        if (signature.isBlank() || lastAcceptedOfferSignature.isBlank()) {
            return false
        }

        return signature == lastAcceptedOfferSignature
    }

    private fun isDuplicateMoveSjCoreOffer(coreSignature: String): Boolean {
        if (coreSignature.isBlank() || lastAcceptedMoveSjCoreSignature.isBlank()) {
            return false
        }

        return coreSignature == lastAcceptedMoveSjCoreSignature
    }

    private fun isDuplicatePassengerRouteOffer(passengerRouteSignature: String): Boolean {
        if (
            passengerRouteSignature.isBlank() ||
                lastAcceptedPassengerRouteSignature.isBlank()
        ) {
            return false
        }

        return passengerRouteSignature == lastAcceptedPassengerRouteSignature
    }

    private fun resolveAppKey(packageName: String): String? {
        return when {
            packageName == moveSjDriverPackage -> "MoveSj"
            packageName == meLevaSjDriverPackage -> "MeLevaSJ"
            packageName == googlePhotosPackage -> "GooglePhotos"
            isNinetyNineContext(packageName) -> "99"
            else -> null
        }
    }

    private fun resolveOfferAppKey(offerData: Map<String, Any>): String? {
        val appValue =
            offerData["platform_name"]?.toString()?.takeIf { it.isNotBlank() }
                ?: offerData["app"]?.toString()?.takeIf { it.isNotBlank() }
                ?: return null

        return when {
            appValue.equals("MoveSj", ignoreCase = true) -> "MoveSj"
            appValue.equals("MeLevaSJ", ignoreCase = true) -> "MeLevaSJ"
            appValue.equals("GooglePhotos", ignoreCase = true) -> "GooglePhotos"
            appValue.contains("99", ignoreCase = true) -> "99"
            else -> appValue
        }
    }

    private fun buildMoveSjCoreSignature(offerData: Map<String, Any>): String {
        return listOf(
            normalizeFingerprintValue(resolveOfferAppKey(offerData)),
            normalizeFingerprintValue(offerData["valor_bruto"]?.toString()),
            normalizeFingerprintValue(offerData["km_total"]?.toString()),
            normalizeFingerprintValue(offerData["minutos_total"]?.toString()),
            normalizeFingerprintValue(offerData["passenger_name"]?.toString()),
        ).joinToString("|")
    }

    private fun buildPassengerRouteSignature(offerData: Map<String, Any>): String {
        val passengerName = normalizeFingerprintValue(offerData["passenger_name"]?.toString())
        val originAddress = normalizeFingerprintValue(offerData["origin_address"]?.toString())
        val destinationAddress =
            normalizeFingerprintValue(offerData["destination_address"]?.toString())

        if (passengerName.isBlank() || (originAddress.isBlank() && destinationAddress.isBlank())) {
            return ""
        }

        return listOf(
            normalizeFingerprintValue(resolveOfferAppKey(offerData)),
            passengerName,
            originAddress,
            destinationAddress,
        ).joinToString("|")
    }

    private fun hasValidPassengerName(offerData: Map<String, Any>): Boolean {
        val passengerName = normalizeFingerprintValue(offerData["passenger_name"]?.toString())
        if (passengerName.isBlank()) {
            return false
        }

        val appKey = normalizeFingerprintValue(resolveOfferAppKey(offerData))
        val blockedValues =
            setOf(
                "app",
                "cliente",
                "clientenaoinformado",
                "corrida",
                "direcao",
                "direcaofinanceira",
                "move",
                "movesj",
                "motorista",
                "passageiro",
            )

        return passengerName !in blockedValues && passengerName != appKey
    }

    private fun normalizeFingerprintValue(value: String?): String {
        if (value.isNullOrBlank()) {
            return ""
        }

        val normalized =
            Normalizer.normalize(value.trim(), Normalizer.Form.NFD)
                .replace("\\p{InCombiningDiacriticalMarks}+".toRegex(), "")

        return normalized.lowercase().replace(" ", "")
    }

    private fun normalizedText(value: String?): String {
        if (value.isNullOrBlank()) {
            return ""
        }

        val normalized =
            Normalizer.normalize(value, Normalizer.Form.NFD)
                .replace("\\p{InCombiningDiacriticalMarks}+".toRegex(), "")

        return normalized.lowercase()
    }

    private fun isExpiredRideRequestOcrText(
        rawText: String,
        lines: List<String>,
    ): Boolean {
        val normalizedScreenText = normalizedText(
            listOf(rawText, lines.joinToString(" ")).joinToString(" "),
        )

        return normalizedScreenText.contains("infelizmente o tempo para aceitar") &&
            normalizedScreenText.contains("solicitacao expirou")
    }

    private fun requestMoveSjOcr(
        displayId: Int,
        attempt: Int = 1,
        sourceAppKey: String = "MoveSj",
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            logLockscreenMessage("ocr_skip_sdk_too_old")
            return
        }

        if (ocrInFlight) {
            logLockscreenMessage(
                "ocr_skip_in_flight",
                extra = mapOf("attempt" to attempt),
            )
            if (attempt < maxMoveSjOcrAttempts) {
                scheduleMoveSjOcrProcessing(displayId, attempt)
            }
            return
        }

        val now = SystemClock.elapsedRealtime()
        if (attempt == 1 && now - lastOcrAtElapsed < minimumMoveSjOcrIntervalMs) {
            logLockscreenMessage(
                "ocr_skip_cooldown",
                extra =
                    mapOf(
                        "source" to sourceAppKey,
                        "elapsedSinceLastOcrMs" to (now - lastOcrAtElapsed),
                    ),
            )
            return
        }

        lastOcrAtElapsed = now
        val ocrToken =
            beginOcrRequest(
                extra =
                    mapOf(
                        "source" to sourceAppKey,
                        "displayId" to displayId,
                        "attempt" to attempt,
                    ),
            )

        val screenshotDisplayId = if (displayId >= 0) displayId else Display.DEFAULT_DISPLAY

        try {
            takeScreenshot(
                screenshotDisplayId,
                mainExecutor,
                object : TakeScreenshotCallback {
                    override fun onSuccess(screenshot: ScreenshotResult) {
                        logLockscreenMessage(
                            "ocr_screenshot_success",
                            extra = mapOf("ocrToken" to ocrToken, "source" to sourceAppKey),
                        )
                        val bitmap = screenshotToBitmap(screenshot)
                        if (bitmap == null) {
                            logLockscreenMessage(
                                "ocr_bitmap_null",
                                extra = mapOf("ocrToken" to ocrToken, "source" to sourceAppKey),
                            )
                            finishOcrRequest(ocrToken, "ocr_request_finished_bitmap_null")
                            scheduleMoveSjRetry(displayId, attempt, "bitmap_null", sourceAppKey)
                            return
                        }

                        runCatching {
                            runMoveSjOcr(
                                bitmap = bitmap,
                                displayId = displayId,
                                attempt = attempt,
                                ocrToken = ocrToken,
                                sourceAppKey = sourceAppKey,
                            )
                        }.onFailure { error ->
                            runCatching { bitmap.recycle() }
                            logLockscreenMessage(
                                "ocr_start_failure",
                                extra =
                                    mapOf(
                                        "ocrToken" to ocrToken,
                                        "source" to sourceAppKey,
                                        "message" to (error.message ?: error::class.java.simpleName),
                                    ),
                            )
                            finishOcrRequest(ocrToken, "ocr_request_finished_start_failure")
                            scheduleMoveSjRetry(displayId, attempt, "start_failure", sourceAppKey)
                        }
                    }

                    override fun onFailure(errorCode: Int) {
                        logLockscreenMessage(
                            "ocr_screenshot_failure",
                            extra =
                                mapOf(
                                    "ocrToken" to ocrToken,
                                    "source" to sourceAppKey,
                                    "errorCode" to errorCode,
                                ),
                        )
                        finishOcrRequest(ocrToken, "ocr_request_finished_screenshot_failure")
                        scheduleMoveSjRetry(displayId, attempt, "screenshot_failure", sourceAppKey)
                    }
                },
            )
        } catch (error: Throwable) {
            logLockscreenMessage(
                "ocr_screenshot_request_throw",
                extra =
                    mapOf(
                        "ocrToken" to ocrToken,
                        "source" to sourceAppKey,
                        "message" to (error.message ?: error::class.java.simpleName),
                    ),
            )
            finishOcrRequest(ocrToken, "ocr_request_finished_request_throw")
            scheduleMoveSjRetry(displayId, attempt, "request_throw", sourceAppKey)
        }
    }

    private fun requestNinetyNineOcr(
        displayId: Int,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            logLockscreenMessage("ocr_skip_sdk_too_old")
            return
        }

        if (ocrInFlight) {
            logLockscreenMessage("ocr_skip_in_flight", extra = mapOf("source" to "99"))
            return
        }

        val now = SystemClock.elapsedRealtime()
        if (now - lastOcrAtElapsed < minimumOcrIntervalMs) {
            logLockscreenMessage(
                "ocr_skip_cooldown",
                extra =
                    mapOf(
                        "source" to "99",
                        "elapsedSinceLastOcrMs" to (now - lastOcrAtElapsed),
                    ),
            )
            return
        }

        lastOcrAtElapsed = now
        val ocrToken =
            beginOcrRequest(
                extra =
                    mapOf(
                        "source" to "99",
                        "displayId" to displayId,
                    ),
            )

        val screenshotDisplayId = if (displayId >= 0) displayId else Display.DEFAULT_DISPLAY

        try {
            takeScreenshot(
                screenshotDisplayId,
                mainExecutor,
                object : TakeScreenshotCallback {
                    override fun onSuccess(screenshot: ScreenshotResult) {
                        logLockscreenMessage(
                            "ocr_screenshot_success",
                            extra = mapOf("ocrToken" to ocrToken, "source" to "99"),
                        )
                        val bitmap = screenshotToBitmap(screenshot)
                        if (bitmap == null) {
                            logLockscreenMessage(
                                "ocr_bitmap_null",
                                extra = mapOf("ocrToken" to ocrToken, "source" to "99"),
                            )
                            finishOcrRequest(ocrToken, "ocr_request_finished_bitmap_null")
                            return
                        }

                        runCatching {
                            runNinetyNineOcr(bitmap, ocrToken)
                        }.onFailure { error ->
                            runCatching { bitmap.recycle() }
                            logLockscreenMessage(
                                "ocr_start_failure",
                                extra =
                                    mapOf(
                                        "ocrToken" to ocrToken,
                                        "source" to "99",
                                        "message" to (error.message ?: error::class.java.simpleName),
                                    ),
                            )
                            finishOcrRequest(ocrToken, "ocr_request_finished_start_failure")
                        }
                    }

                    override fun onFailure(errorCode: Int) {
                        logLockscreenMessage(
                            "ocr_screenshot_failure",
                            extra =
                                mapOf(
                                    "ocrToken" to ocrToken,
                                    "source" to "99",
                                    "errorCode" to errorCode,
                                ),
                        )
                        finishOcrRequest(ocrToken, "ocr_request_finished_screenshot_failure")
                    }
                },
            )
        } catch (error: Throwable) {
            logLockscreenMessage(
                "ocr_screenshot_request_throw",
                extra =
                    mapOf(
                        "ocrToken" to ocrToken,
                        "source" to "99",
                        "message" to (error.message ?: error::class.java.simpleName),
                    ),
            )
            finishOcrRequest(ocrToken, "ocr_request_finished_request_throw")
        }
    }

    private fun beginOcrRequest(extra: Map<String, Any?>): Int {
        activeOcrToken += 1
        val ocrToken = activeOcrToken
        ocrInFlight = true

        ocrWatchdogRunnable?.let(mainHandler::removeCallbacks)
        ocrWatchdogRunnable =
            Runnable {
                if (ocrInFlight && activeOcrToken == ocrToken) {
                    logLockscreenMessage(
                        "ocr_watchdog_timeout",
                        extra = extra + mapOf("ocrToken" to ocrToken),
                    )
                    ocrInFlight = false
                    ocrWatchdogRunnable = null
                }
            }.also { runnable ->
                mainHandler.postDelayed(runnable, ocrWatchdogTimeoutMs)
            }

        logLockscreenMessage(
            "ocr_request_start",
            extra = extra + mapOf("ocrToken" to ocrToken),
        )
        return ocrToken
    }

    private fun finishOcrRequest(
        ocrToken: Int,
        stage: String,
        extra: Map<String, Any?> = emptyMap(),
    ) {
        if (ocrToken != activeOcrToken) {
            logLockscreenMessage(
                "ocr_request_stale_finish",
                extra = extra + mapOf("ocrToken" to ocrToken, "activeOcrToken" to activeOcrToken),
            )
            return
        }

        ocrWatchdogRunnable?.let(mainHandler::removeCallbacks)
        ocrWatchdogRunnable = null
        ocrInFlight = false
        logLockscreenMessage(stage, extra = extra + mapOf("ocrToken" to ocrToken))
    }

    private fun scheduleMoveSjRetry(
        displayId: Int,
        attempt: Int,
        reason: String,
        sourceAppKey: String = "MoveSj",
        extra: Map<String, Any?> = emptyMap(),
    ) {
        if (attempt >= maxMoveSjOcrAttempts) {
            logLockscreenMessage(
                "movesj_ocr_retry_exhausted",
                extra = extra + mapOf("attempt" to attempt, "reason" to reason),
            )
            return
        }
        if (!SettingsManager.shouldKeepRuntimeActive() || !SettingsManager.shouldShowTrafficLight()) {
            logLockscreenMessage(
                "movesj_ocr_retry_runtime_inactive",
                extra = extra + mapOf("attempt" to attempt, "reason" to reason),
            )
            return
        }

        logLockscreenMessage(
            "movesj_ocr_retry_scheduled",
            extra =
                extra +
            mapOf(
                "attempt" to attempt,
                "nextAttempt" to (attempt + 1),
                "reason" to reason,
                "sourceAppKey" to sourceAppKey,
            ),
        )
        scheduleMoveSjOcrProcessing(displayId, attempt + 1, sourceAppKey)
    }

    private fun shouldRetryMoveSjParse(
        lines: List<String>,
        attempt: Int,
    ): Boolean {
        if (attempt >= maxMoveSjOcrAttempts) {
            return false
        }

        val normalized = lines.joinToString(" ").lowercase()
        return normalized.contains("r$") ||
            normalized.contains("aceitar") ||
            normalized.contains("recusar") ||
            normalized.contains("km") ||
            normalized.contains("min")
    }

    private fun runMoveSjOcr(
        bitmap: Bitmap,
        displayId: Int,
        attempt: Int,
        ocrToken: Int,
        sourceAppKey: String,
    ) {
        val image = InputImage.fromBitmap(bitmap, 0)
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

        recognizer
            .process(image)
            .addOnSuccessListener { visionText ->
                runCatching {
                    val ocrLines =
                        visionText.textBlocks
                            .flatMap { block -> block.lines }
                            .sortedWith(
                                compareBy(
                                    { line -> line.boundingBox?.top ?: Int.MAX_VALUE },
                                    { line -> line.boundingBox?.left ?: Int.MAX_VALUE },
                                ),
                            )
                            .mapNotNull { line ->
                                val text = line.text.trim()
                                val box = line.boundingBox
                                if (text.isEmpty() || box == null) {
                                    null
                                } else {
                                    MoveSjParser.OcrLine(
                                        text = text,
                                        left = box.left,
                                        top = box.top,
                                        right = box.right,
                                        bottom = box.bottom,
                                    )
                                }
                            }
                    val lines = ocrLines.map { it.text }

                    if (isExpiredRideRequestOcrText(visionText.text, lines)) {
                        stopRideOfferPresentation()
                        logLockscreenMessage(
                            "ocr_expired_ride_request_dialog",
                            extra = mapOf("ocrToken" to ocrToken, "source" to "MoveSj"),
                        )
                        return@runCatching
                    }

                    val offerData =
                        when (sourceAppKey) {
                            "MeLevaSJ" ->
                                meLevaSjParser.parsePositionedOcrOffer(visionText.text, ocrLines)
                            else ->
                                moveSjParser.parsePositionedOcrOffer(visionText.text, ocrLines)
                        }
                    logLockscreenMessage(
                        "ocr_result",
                        extra =
                            mapOf(
                                "ocrToken" to ocrToken,
                                "source" to sourceAppKey,
                                "attempt" to attempt,
                                "lineCount" to lines.size,
                                "parsedOffer" to (offerData != null),
                            ),
                    )
                    if (offerData != null) {
                        logLockscreenMessage("ocr_offer_parsed", extra = offerLogSummary(offerData))
                        enrichRouteIfNeededAndProcess(offerData, displayId, attempt, ocrToken)
                    } else if (shouldRetryMoveSjParse(lines, attempt)) {
                        scheduleMoveSjRetry(
                            displayId = displayId,
                            attempt = attempt,
                            reason = "parse_incomplete",
                            sourceAppKey = sourceAppKey,
                            extra = mapOf("lineCount" to lines.size),
                        )
                    } else {
                        restoreAppBubbleAfterRideOffer()
                    }
                }.onFailure { error ->
                    logLockscreenMessage(
                        "ocr_parse_failure",
                        extra =
                            mapOf(
                                "ocrToken" to ocrToken,
                                "source" to sourceAppKey,
                                "attempt" to attempt,
                                "message" to (error.message ?: error::class.java.simpleName),
                            ),
                    )
                    scheduleMoveSjRetry(displayId, attempt, "parse_failure", sourceAppKey)
                }
            }
            .addOnFailureListener { error ->
                logLockscreenMessage(
                    "ocr_failure",
                    extra =
                        mapOf(
                            "ocrToken" to ocrToken,
                            "source" to sourceAppKey,
                            "attempt" to attempt,
                            "message" to (error.message ?: ""),
                        ),
                )
                scheduleMoveSjRetry(displayId, attempt, "ocr_failure", sourceAppKey)
            }
            .addOnCompleteListener {
                runCatching { bitmap.recycle() }
                runCatching { recognizer.close() }
                finishOcrRequest(
                    ocrToken,
                    "ocr_request_complete",
                    mapOf("source" to sourceAppKey, "attempt" to attempt),
                )
            }
    }

    private fun enrichRouteIfNeededAndProcess(
        offerData: Map<String, Any>,
        displayId: Int,
        attempt: Int,
        ocrToken: Int,
    ) {
        val kmTotal = (offerData["km_total"] as? Number)?.toDouble() ?: 0.0
        val totalMinutes = (offerData["minutos_total"] as? Number)?.toInt() ?: 0
        val originAddress = offerData["origin_address"]?.toString().orEmpty().trim()
        val destinationAddress = offerData["destination_address"]?.toString().orEmpty().trim()

        val needsRouteEstimate =
            (kmTotal <= 0.0 || totalMinutes <= 0) &&
                originAddress.isNotBlank() &&
                destinationAddress.isNotBlank()

        if (!needsRouteEstimate) {
            processOffer(offerData)
            return
        }

        val apiKey = SettingsManager.googleMapsApiKey.trim()
        if (apiKey.isBlank()) {
            logLockscreenMessage(
                "route_enrichment_skipped_no_key",
                extra = offerLogSummary(offerData),
            )
            return
        }

        Thread {
            val routeEstimate =
                runCatching {
                    estimateRoute(originAddress, destinationAddress, apiKey)
                }.getOrNull()

            val enrichedOffer =
                if (routeEstimate != null) {
                    offerData + mapOf(
                        "km_total" to routeEstimate.first,
                        "minutos_total" to routeEstimate.second,
                    )
                } else {
                    offerData
                }

            mainHandler.post {
                if (ocrToken != activeOcrToken) {
                    logLockscreenMessage(
                        "route_enrichment_stale_result",
                        extra =
                            mapOf(
                                "ocrToken" to ocrToken,
                                "activeOcrToken" to activeOcrToken,
                                "attempt" to attempt,
                                "displayId" to displayId,
                            ),
                    )
                    return@post
                }

                if (routeEstimate == null) {
                    logLockscreenMessage(
                        "route_enrichment_failed",
                        extra = offerLogSummary(offerData),
                    )
                } else {
                    logLockscreenMessage(
                        "route_enrichment_success",
                        extra =
                            offerLogSummary(
                                enrichedOffer + mapOf(
                                    "km_total" to routeEstimate.first,
                                    "minutos_total" to routeEstimate.second,
                                ),
                            ),
                    )
                }

                processOffer(enrichedOffer)
            }
        }.start()
    }

    private fun estimateRoute(
        originAddress: String,
        destinationAddress: String,
        apiKey: String,
    ): Pair<Double, Int>? {
        val originQueries = googleRouteQueries(originAddress)
        val destinationQueries = googleRouteQueries(destinationAddress)

        for (origin in originQueries) {
            for (destination in destinationQueries) {
                val responseJson =
                    runCatching {
                        postRoutesRequest(origin, destination, apiKey)
                    }.getOrNull() ?: continue

                val routes = responseJson.optJSONArray("routes") ?: continue
                if (routes.length() == 0) {
                    continue
                }

                val route = routes.optJSONObject(0) ?: continue
                val distanceMeters = route.optDouble("distanceMeters", -1.0)
                val durationSeconds = googleDurationSeconds(route.optString("duration"))
                if (distanceMeters > 0.0 && durationSeconds > 0.0) {
                    return Pair(distanceMeters / 1000.0, (durationSeconds / 60.0).toInt().coerceAtLeast(1))
                }
            }
        }

        return null
    }

    private fun postRoutesRequest(
        origin: String,
        destination: String,
        apiKey: String,
    ): JSONObject? {
        val connection =
            URL("https://routes.googleapis.com/directions/v2:computeRoutes").openConnection() as HttpURLConnection
        return try {
            val payload =
                JSONObject()
                    .put("origin", JSONObject().put("address", origin))
                    .put("destination", JSONObject().put("address", destination))
                    .put("travelMode", "DRIVE")
                    .put("languageCode", "pt-BR")
                    .put("regionCode", "BR")

            connection.requestMethod = "POST"
            connection.connectTimeout = 8000
            connection.readTimeout = 5000
            connection.doOutput = true
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("X-Goog-Api-Key", apiKey)
            connection.setRequestProperty(
                "X-Goog-FieldMask",
                "routes.distanceMeters,routes.duration",
            )

            connection.outputStream.use { output ->
                output.write(payload.toString().toByteArray(Charsets.UTF_8))
            }

            val code = connection.responseCode
            if (code !in 200..299) {
                null
            } else {
                val body =
                    connection.inputStream.bufferedReader().use { it.readText() }
                JSONObject(body)
            }
        } finally {
            connection.disconnect()
        }
    }

    private fun googleRouteQueries(address: String): List<String> {
        val normalized = normalizeAddress(address)
        val streetCandidate = extractStreetCandidate(normalized)
        val establishmentCandidate = normalized.split(Regex("\\s+-\\s+")).firstOrNull()?.trim().orEmpty()

        return listOf(
            googleAddressQuery(normalized),
            googleAddressQuery(streetCandidate),
            googleAddressQuery(establishmentCandidate),
        ).filter { it.isNotBlank() }.distinct()
    }

    private fun googleAddressQuery(address: String): String {
        val normalized = normalizeAddress(address)
        return if (normalized.lowercase().contains("brasil")) {
            normalized
        } else {
            "$normalized, Sao Joao del Rei, MG, Brasil"
        }
    }

    private fun extractStreetCandidate(address: String): String {
        val parts =
            address
                .split(Regex("\\s+-\\s+"))
                .map { it.trim() }
                .filter { it.isNotEmpty() }
        val streetIndex =
            parts.indexOfFirst {
                Regex("^(Rua|Avenida|Av\\.|R\\.|Travessa|Praca)\\b", RegexOption.IGNORE_CASE).containsMatchIn(it)
            }
        return if (streetIndex < 0) address else parts.drop(streetIndex).joinToString(", ")
    }

    private fun normalizeAddress(address: String): String {
        return address
            .replace("\n", " ")
            .replace(Regex("\\s+"), " ")
            .replace(Regex("\\bAv\\.\\s*", RegexOption.IGNORE_CASE), "Avenida ")
            .replace(Regex("\\bR\\.\\s*", RegexOption.IGNORE_CASE), "Rua ")
            .replace(Regex("\\bPca\\.\\s*", RegexOption.IGNORE_CASE), "Praca ")
            .replace(Regex("\\bPraca\\b", RegexOption.IGNORE_CASE), "Praca")
            .replace(Regex("\\bSao\\b", RegexOption.IGNORE_CASE), "Sao")
            .trim()
    }

    private fun googleDurationSeconds(value: String?): Double {
        if (value.isNullOrBlank()) {
            return -1.0
        }

        val normalized = value.trim().removeSuffix("s")
        return normalized.toDoubleOrNull() ?: -1.0
    }

    private fun runNinetyNineOcr(
        bitmap: Bitmap,
        ocrToken: Int,
    ) {
        val croppedBitmap = cropOfferRegion(bitmap)
        bitmap.recycle()

        val image = InputImage.fromBitmap(croppedBitmap, 0)
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

        recognizer
            .process(image)
            .addOnSuccessListener { visionText ->
                runCatching {
                    val lines =
                        visionText.textBlocks
                            .flatMap { block -> block.lines }
                            .sortedWith(
                                compareBy(
                                    { line -> line.boundingBox?.top ?: Int.MAX_VALUE },
                                    { line -> line.boundingBox?.left ?: Int.MAX_VALUE },
                                ),
                            )
                            .map { line -> line.text.trim() }
                            .filter { it.isNotEmpty() }

                    if (isExpiredRideRequestOcrText(visionText.text, lines)) {
                        stopRideOfferPresentation()
                        logLockscreenMessage(
                            "ocr_expired_ride_request_dialog",
                            extra = mapOf("ocrToken" to ocrToken, "source" to "99"),
                        )
                        return@runCatching
                    }

                    val offerData = ninetyNineOcrParser.parseOffer(visionText.text, lines)
                    logLockscreenMessage(
                        "ocr_result",
                        extra =
                            mapOf(
                                "ocrToken" to ocrToken,
                                "source" to "99",
                                "lineCount" to lines.size,
                                "parsedOffer" to (offerData != null),
                            ),
                    )
                    if (offerData != null) {
                        logLockscreenMessage("ocr_offer_parsed", extra = offerLogSummary(offerData))
                        processOffer(offerData)
                    } else {
                        restoreAppBubbleAfterRideOffer()
                    }
                }.onFailure { error ->
                    logLockscreenMessage(
                        "ocr_parse_failure",
                        extra =
                            mapOf(
                                "ocrToken" to ocrToken,
                                "source" to "99",
                                "message" to (error.message ?: error::class.java.simpleName),
                            ),
                    )
                }
            }
            .addOnFailureListener { error ->
                logLockscreenMessage(
                    "ocr_failure",
                    extra =
                        mapOf(
                            "ocrToken" to ocrToken,
                            "source" to "99",
                            "message" to (error.message ?: ""),
                        ),
                )
            }
            .addOnCompleteListener {
                runCatching { croppedBitmap.recycle() }
                runCatching { recognizer.close() }
                finishOcrRequest(
                    ocrToken,
                    "ocr_request_complete",
                    mapOf("source" to "99"),
                )
            }
    }

    private fun cropOfferRegion(bitmap: Bitmap): Bitmap {
        val top = (bitmap.height * 0.32f).toInt().coerceIn(0, bitmap.height - 1)
        val height = (bitmap.height - top).coerceAtLeast(1)
        return Bitmap.createBitmap(bitmap, 0, top, bitmap.width, height)
    }

    private fun screenshotToBitmap(screenshot: ScreenshotResult): Bitmap? {
        return try {
            val hardwareBuffer: HardwareBuffer = screenshot.hardwareBuffer
            val colorSpace: ColorSpace = screenshot.colorSpace
            val hardwareBitmap = Bitmap.wrapHardwareBuffer(hardwareBuffer, colorSpace)
            val bitmap = hardwareBitmap?.copy(Bitmap.Config.ARGB_8888, false)
            hardwareBuffer.close()
            hardwareBitmap?.recycle()
            bitmap
        } catch (_: Throwable) {
            null
        }
    }

    private fun notifyFlutter(data: Map<String, Any>) {
        mainHandler.post {
            runCatching {
                val currentChannel = channel
                if (currentChannel == null) {
                    logLockscreenMessage("flutter_notify_channel_null", extra = offerLogSummary(data))
                    enqueuePendingDetectedRide(this, data)
                    return@runCatching
                }

                currentChannel.invokeMethod(
                    "onRaceDetected",
                    data,
                    object : MethodChannel.Result {
                        override fun success(result: Any?) {
                            debugLog(
                                "MoveSj invokeMethod onRaceDetected persisted summary=${offerLogSummary(data)}",
                            )
                        }

                        override fun error(
                            errorCode: String,
                            errorMessage: String?,
                            errorDetails: Any?,
                        ) {
                            logLockscreenMessage(
                                "flutter_notify_result_error",
                                extra =
                                    mapOf(
                                        "code" to errorCode,
                                        "message" to (errorMessage ?: ""),
                                    ),
                            )
                            enqueuePendingDetectedRide(this@ScreenReaderService, data)
                        }

                        override fun notImplemented() {
                            logLockscreenMessage(
                                "flutter_notify_not_implemented",
                                extra = offerLogSummary(data),
                            )
                            enqueuePendingDetectedRide(this@ScreenReaderService, data)
                        }
                    },
                )
                debugLog("MoveSj invokeMethod onRaceDetected summary=${offerLogSummary(data)}")
            }.onFailure { error ->
                logLockscreenMessage(
                    "flutter_notify_failure",
                    extra = mapOf("message" to (error.message ?: error::class.java.simpleName)),
                )
                enqueuePendingDetectedRide(this, data)
            }
        }
    }

    override fun onInterrupt() {
        pendingOverlayRunnable?.let(mainHandler::removeCallbacks)
        pendingMoveSjRunnable?.let(mainHandler::removeCallbacks)
        pendingNinetyNineRunnable?.let(mainHandler::removeCallbacks)
        ocrWatchdogRunnable?.let(mainHandler::removeCallbacks)
        pendingOverlayRunnable = null
        pendingMoveSjRunnable = null
        pendingNinetyNineRunnable = null
        ocrWatchdogRunnable = null
        ocrInFlight = false
        floatingOverlay?.hide()
        restoreAppBubbleAfterRideOffer()
        logLockscreenMessage("service_interrupt")
    }

    private fun hideAppBubbleForRideOffer() {
        AppBubbleService.hideForRideOffer(this)
    }

    private fun restoreAppBubbleAfterRideOffer() {
        AppBubbleService.restoreAfterRideOffer(this)
    }

    private fun stopRideOfferPresentation() {
        pendingOverlayRunnable?.let(mainHandler::removeCallbacks)
        pendingMoveSjRunnable?.let(mainHandler::removeCallbacks)
        pendingNinetyNineRunnable?.let(mainHandler::removeCallbacks)
        pendingOverlayRunnable = null
        pendingMoveSjRunnable = null
        pendingNinetyNineRunnable = null
        floatingOverlay?.hide()
        rideOfferNotificationDispatcher?.dismissLast()
        restoreAppBubbleAfterRideOffer()
    }

    private fun logLockscreenEvent(
        stage: String,
        event: AccessibilityEvent,
        extra: Map<String, Any?> = emptyMap(),
    ) {
        logLockscreenMessage(
            stage,
            extra =
                buildMap {
                    put("eventType", event.eventType)
                    put("eventPackage", event.packageName?.toString().orEmpty())
                    put("isKeyguardLocked", isKeyguardLocked())
                    put("isDeviceLocked", isDeviceLockedCompat())
                    putAll(extra)
                },
        )
    }

    private fun logLockscreenMessage(
        stage: String,
        extra: Map<String, Any?> = emptyMap(),
    ) {
        debugLog("$lockLogPrefix stage=$stage ${extra.entries.joinToString(" ") { "${it.key}=${it.value}" }}")
    }

    private fun debugLog(message: String) {
        if (isDebugBuild()) {
            Log.d(logTag, message)
        }
    }

    private fun isDebugBuild(): Boolean {
        return (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
    }

    private fun isKeyguardLocked(): Boolean {
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
        return keyguardManager?.isKeyguardLocked == true
    }

    private fun isDeviceLockedCompat(): Boolean {
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            keyguardManager?.isDeviceLocked == true
        } else {
            false
        }
    }
}
