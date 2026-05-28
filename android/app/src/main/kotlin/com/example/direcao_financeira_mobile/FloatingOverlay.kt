package com.example.direcao_financeira_mobile

import android.content.Context
import android.content.pm.ApplicationInfo
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import kotlin.math.max

class FloatingOverlay(
    private val context: Context,
) {
    private val logTag = "DF-MoveSjDebug"
    private val lockLogPrefix = "LOCK_DEBUG"
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var cardView: LinearLayout? = null
    private var metricsRow: LinearLayout? = null
    private var currentLayoutParams: WindowManager.LayoutParams? = null
    private var isShowing = false
    private val handler = Handler(Looper.getMainLooper())
    private var hideRunnable: Runnable? = null
    private var layoutSignature: String? = null
    private val metricValueViews = mutableListOf<TextView>()
    private val metricBarViews = mutableListOf<View>()
    private val metricLabelViews = mutableListOf<TextView>()
    private var badgeTextView: TextView? = null
    private var summaryTextView: TextView? = null

    fun show(data: Map<String, Any>) {
        windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        debugLog("$lockLogPrefix overlay_show_called app=${data["platform_name"] ?: data["app"]} isShowing=$isShowing")
        val signature = buildLayoutSignature()
        val shouldRebuild =
            !isShowing || overlayView == null || currentLayoutParams == null || layoutSignature != signature

        if (shouldRebuild) {
            layoutSignature = signature
            buildOverlay()
        }

        bindData(data)
        scheduleHide()
    }

    fun hide() {
        hideRunnable?.let(handler::removeCallbacks)
        hideRunnable = null

        if (isShowing && overlayView != null) {
            try {
                windowManager?.removeView(overlayView)
                debugLog("$lockLogPrefix overlay_hide_success")
            } catch (_: Exception) {
                debugLog("$lockLogPrefix overlay_hide_failure")
            }
        }

        isShowing = false
        overlayView = null
        cardView = null
        metricsRow = null
        currentLayoutParams = null
        metricValueViews.clear()
        metricBarViews.clear()
        metricLabelViews.clear()
        badgeTextView = null
        summaryTextView = null
    }

    private fun buildOverlay() {
        hide()

        val wm = windowManager ?: return
        val screenWidth = context.resources.displayMetrics.widthPixels
        val screenHeight = context.resources.displayMetrics.heightPixels
        val horizontalMargin = dpToPx(16f)
        val sidePosition = SettingsManager.position == 1 || SettingsManager.position == 2
        val cardWidth =
            (screenWidth - (horizontalMargin * 2))
                .coerceAtMost(if (sidePosition) dpToPx(280f) else dpToPx(380f))

        val container = FrameLayout(context)
        val card =
            LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(dpToPx(18f), dpToPx(18f), dpToPx(18f), dpToPx(18f))
                layoutParams =
                    FrameLayout.LayoutParams(
                        cardWidth,
                        FrameLayout.LayoutParams.WRAP_CONTENT,
                    )
            }

        val row =
            LinearLayout(context).apply {
                orientation =
                    if (sidePosition) {
                        LinearLayout.VERTICAL
                    } else {
                        LinearLayout.HORIZONTAL
                    }
                gravity =
                    if (sidePosition) {
                        Gravity.START
                    } else {
                        Gravity.CENTER_VERTICAL
                    }
                if (!sidePosition) {
                    weightSum = enabledIndicators().size.toFloat().coerceAtLeast(1f)
                }
            }
        metricsRow = row

        enabledIndicators().forEach { indicator ->
            val metricColumn =
                LinearLayout(context).apply {
                    orientation = LinearLayout.VERTICAL
                    layoutParams =
                        if (sidePosition) {
                            LinearLayout.LayoutParams(
                                LinearLayout.LayoutParams.MATCH_PARENT,
                                LinearLayout.LayoutParams.WRAP_CONTENT,
                            ).apply {
                                bottomMargin = dpToPx(12f)
                            }
                        } else {
                            LinearLayout.LayoutParams(
                                0,
                                LinearLayout.LayoutParams.WRAP_CONTENT,
                                1f,
                            )
                        }
                }

            val labelView =
                TextView(context).apply {
                    text = indicator.overlayLabel
                    typeface = Typeface.DEFAULT_BOLD
                }
            metricLabelViews.add(labelView)
            metricColumn.addView(labelView)
            metricColumn.addView(spacer(10f))

            val valueRow =
                LinearLayout(context).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER_VERTICAL
                }

            val accentBar =
                View(context).apply {
                    layoutParams = LinearLayout.LayoutParams(dpToPx(6f), dpToPx(34f))
                }
            metricBarViews.add(accentBar)
            valueRow.addView(accentBar)

            val valueView =
                TextView(context).apply {
                    text = "--"
                    typeface = Typeface.DEFAULT_BOLD
                    setPadding(dpToPx(10f), 0, 0, 0)
                }
            metricValueViews.add(valueView)
            valueRow.addView(valueView)

            metricColumn.addView(valueRow)
            row.addView(metricColumn)
        }

        card.addView(row)
        card.addView(spacer(18f))

        val footerRow =
            LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
            }

        badgeTextView =
            TextView(context).apply {
                text = "APP"
                typeface = Typeface.DEFAULT_BOLD
                setPadding(dpToPx(8f), dpToPx(4f), dpToPx(8f), dpToPx(4f))
            }
        footerRow.addView(badgeTextView)

        summaryTextView =
            TextView(context).apply {
                text = "0h00m · 0.0km"
                typeface = Typeface.DEFAULT_BOLD
                setPadding(dpToPx(12f), 0, 0, 0)
            }
        footerRow.addView(summaryTextView)

        card.addView(footerRow)
        container.addView(card)
        overlayView = container
        cardView = card

        applyVisualStyle(signalColor = resolveSignalColor(OverlaySignalStatus.GOOD))
        card.setOnClickListener { hide() }
        attachDragBehavior(card)

        container.measure(
            View.MeasureSpec.makeMeasureSpec(screenWidth, View.MeasureSpec.AT_MOST),
            View.MeasureSpec.makeMeasureSpec(screenHeight, View.MeasureSpec.AT_MOST),
        )

        val overlayWidth = container.measuredWidth
        val overlayHeight = container.measuredHeight
        val initialPosition =
            resolveInitialPosition(
                screenWidth = screenWidth,
                screenHeight = screenHeight,
                overlayWidth = overlayWidth,
                overlayHeight = overlayHeight,
                margin = horizontalMargin,
            )

        val params =
            WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                PixelFormat.TRANSLUCENT,
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = initialPosition.first
                y = initialPosition.second
            }

        currentLayoutParams = params
        debugLog(
            "$lockLogPrefix overlay_add_view type=${params.type} flags=${params.flags} x=${params.x} y=${params.y}",
        )
        wm.addView(container, params)
        isShowing = true
        debugLog("$lockLogPrefix overlay_add_view_success")
    }

    private fun bindData(data: Map<String, Any>) {
        val metrics = extractOfferMetrics(data)
        val signalStatus = evaluateSignalStatus(metrics)
        val signalColor = resolveSignalColor(signalStatus)
        applyVisualStyle(signalColor)

        val indicatorValues =
            enabledIndicators().map { indicator ->
                when (indicator) {
                    OverlayIndicator.GAIN_PER_KM -> formatMetricValue(metrics.gainPerKm)
                    OverlayIndicator.GAIN_PER_HOUR -> formatMetricValue(metrics.gainPerHour)
                    OverlayIndicator.PROFIT_PER_HOUR -> formatMetricValue(metrics.profitValue)
                    OverlayIndicator.RATING -> String.format("%.1f", metrics.rating)
                }
            }

        metricValueViews.forEachIndexed { index, textView ->
            textView.text = indicatorValues.getOrElse(index) { "--" }
        }

        val appName =
            data["platform_name"]?.toString()?.takeIf { it.isNotBlank() }
                ?: data["app"]?.toString()?.takeIf { it.isNotBlank() }
                ?: "APP"
        badgeTextView?.text = appName.uppercase()
        summaryTextView?.text =
            "${formatDuration(metrics.totalMinutes)} · ${String.format("%.1f", metrics.totalKm)}km"

        overlayView?.let { view ->
            currentLayoutParams?.let { params ->
                debugLog(
                    "$lockLogPrefix overlay_update_view x=${params.x} y=${params.y} app=$appName summary=${summaryTextView?.text}",
                )
                windowManager?.updateViewLayout(view, params)
            }
        }
    }

    private fun applyVisualStyle(signalColor: Int) {
        val theme = resolveThemePalette()
        val labelSize = (SettingsManager.fontSize - 2f).coerceAtLeast(10f)
        val valueSize = (SettingsManager.fontSize + 8f).coerceAtLeast(18f)
        val footerSize = (SettingsManager.fontSize + 2f).coerceAtLeast(12f)

        cardView?.background =
            GradientDrawable().apply {
                setColor(theme.backgroundColor)
                cornerRadius = dpToPx(22f).toFloat()
                setStroke(dpToPx(6f), signalColor)
            }
        cardView?.alpha = SettingsManager.opacity / 100f

        metricLabelViews.forEach { labelView ->
            labelView.setTextColor(theme.labelColor)
            labelView.textSize = labelSize
        }

        metricValueViews.forEach { valueView ->
            valueView.setTextColor(theme.primaryTextColor)
            valueView.textSize = valueSize
        }

        metricBarViews.forEach { bar ->
            bar.background =
                GradientDrawable().apply {
                    cornerRadius = dpToPx(8f).toFloat()
                    setColor(signalColor)
                }
        }

        badgeTextView?.apply {
            setTextColor(theme.badgeTextColor)
            textSize = (SettingsManager.fontSize - 5f).coerceAtLeast(9f)
            background =
                GradientDrawable().apply {
                    cornerRadius = dpToPx(6f).toFloat()
                    setColor(theme.badgeBackgroundColor)
                }
        }

        summaryTextView?.apply {
            setTextColor(theme.primaryTextColor)
            textSize = footerSize
        }
    }

    private fun extractOfferMetrics(data: Map<String, Any>): OverlayOfferMetrics {
        val valueText = data["valor_bruto"]?.toString().orEmpty()
        val grossValue =
            valueText.replace(Regex("[^0-9,]"), "")
                .replace(",", ".")
                .toDoubleOrNull() ?: 0.0
        val totalKm = (data["km_total"] as? Number)?.toDouble() ?: 0.0
        val totalMinutes = (data["minutos_total"] as? Number)?.toInt() ?: 0
        val fuelCostValue = calculateFuelCostValue(totalKm)
        val rating =
            data["avaliacao"]?.toString()
                ?.replace("\u2605", "")
                ?.replace("\u2B50", "")
                ?.replace(",", ".")
                ?.toDoubleOrNull() ?: 5.0

        return OverlayOfferMetrics(
            totalKm = totalKm,
            totalMinutes = totalMinutes,
            rating = rating,
            gainPerKm = if (totalKm > 0) grossValue / totalKm else 0.0,
            gainPerHour = if (totalMinutes > 0) (grossValue / totalMinutes) * 60 else 0.0,
            profitValue = grossValue - fuelCostValue,
        )
    }

    private fun calculateFuelCostValue(totalKm: Double): Double {
        if (totalKm <= 0 || SettingsManager.kmPerLiter <= 0 || SettingsManager.fuelPricePerLiterCents <= 0) {
            return 0.0
        }

        val litersUsed = totalKm / SettingsManager.kmPerLiter
        val fuelPricePerLiter = SettingsManager.fuelPricePerLiterCents / 100.0
        return litersUsed * fuelPricePerLiter
    }

    private fun evaluateSignalStatus(metrics: OverlayOfferMetrics): OverlaySignalStatus {
        val statuses = mutableListOf<OverlaySignalStatus>()

        if (SettingsManager.indicators["R$/Km"] == true) {
            statuses.add(
                evaluateThreshold(
                    value = metrics.gainPerKm,
                    badThreshold = SettingsManager.gainPerKmBad,
                    goodThreshold = SettingsManager.gainPerKmGood,
                ),
            )
        }

        if (SettingsManager.indicators["R$/Hora"] == true || SettingsManager.indicators["Lucro/H"] == true) {
            statuses.add(
                evaluateThreshold(
                    value = metrics.gainPerHour,
                    badThreshold = SettingsManager.gainPerHourBad,
                    goodThreshold = SettingsManager.gainPerHourGood,
                ),
            )
        }

        if (SettingsManager.indicators["Nota"] == true) {
            statuses.add(
                evaluateThreshold(
                    value = metrics.rating,
                    badThreshold = SettingsManager.passengerRatingBad,
                    goodThreshold = SettingsManager.passengerRatingGood,
                ),
            )
        }

        if (statuses.isEmpty()) {
            return OverlaySignalStatus.GOOD
        }

        return when {
            statuses.any { it == OverlaySignalStatus.BAD } -> OverlaySignalStatus.BAD
            statuses.any { it == OverlaySignalStatus.MEDIUM } -> OverlaySignalStatus.MEDIUM
            else -> OverlaySignalStatus.GOOD
        }
    }

    private fun evaluateThreshold(
        value: Double,
        badThreshold: Double,
        goodThreshold: Double,
    ): OverlaySignalStatus {
        return when {
            value < badThreshold -> OverlaySignalStatus.BAD
            value >= goodThreshold -> OverlaySignalStatus.GOOD
            else -> OverlaySignalStatus.MEDIUM
        }
    }

    private fun enabledIndicators(): List<OverlayIndicator> {
        val indicators = mutableListOf<OverlayIndicator>()
        if (SettingsManager.indicators["R$/Km"] == true) {
            indicators.add(OverlayIndicator.GAIN_PER_KM)
        }
        if (SettingsManager.indicators["R$/Hora"] == true) {
            indicators.add(OverlayIndicator.GAIN_PER_HOUR)
        }
        if (SettingsManager.indicators["Lucro/H"] == true) {
            indicators.add(OverlayIndicator.PROFIT_PER_HOUR)
        }
        if (SettingsManager.indicators["Nota"] == true) {
            indicators.add(OverlayIndicator.RATING)
        }

        if (indicators.isEmpty()) {
            return listOf(
                OverlayIndicator.GAIN_PER_KM,
                OverlayIndicator.GAIN_PER_HOUR,
                OverlayIndicator.PROFIT_PER_HOUR,
            )
        }

        return indicators
    }

    private fun resolveSignalColor(status: OverlaySignalStatus): Int {
        if (SettingsManager.colorBlind) {
            return when (status) {
                OverlaySignalStatus.GOOD -> Color.parseColor("#1F78FF")
                OverlaySignalStatus.MEDIUM -> Color.parseColor("#F39C12")
                OverlaySignalStatus.BAD -> Color.parseColor("#7E57C2")
            }
        }

        return when (status) {
            OverlaySignalStatus.GOOD -> Color.parseColor("#18B663")
            OverlaySignalStatus.MEDIUM -> Color.parseColor("#F39C12")
            OverlaySignalStatus.BAD -> Color.parseColor("#E74C3C")
        }
    }

    private fun resolveThemePalette(): OverlayThemePalette {
        return when (SettingsManager.theme) {
            0 ->
                OverlayThemePalette(
                    backgroundColor = Color.parseColor("#FFFFFF"),
                    primaryTextColor = Color.parseColor("#161616"),
                    labelColor = Color.parseColor("#7A7A7A"),
                    badgeBackgroundColor = Color.parseColor("#111111"),
                    badgeTextColor = Color.WHITE,
                )
            2 ->
                OverlayThemePalette(
                    backgroundColor = Color.parseColor("#EAF8F0"),
                    primaryTextColor = Color.parseColor("#0B2F1D"),
                    labelColor = Color.parseColor("#3D6B57"),
                    badgeBackgroundColor = Color.parseColor("#0B2F1D"),
                    badgeTextColor = Color.WHITE,
                )
            else ->
                OverlayThemePalette(
                    backgroundColor = Color.parseColor("#131313"),
                    primaryTextColor = Color.parseColor("#F7F7F7"),
                    labelColor = Color.parseColor("#A6A6A6"),
                    badgeBackgroundColor = Color.parseColor("#F2F2F2"),
                    badgeTextColor = Color.parseColor("#111111"),
                )
        }
    }

    private fun buildLayoutSignature(): String {
        return listOf(
            SettingsManager.position,
            SettingsManager.theme,
            SettingsManager.fontSize,
            SettingsManager.opacity,
            SettingsManager.duration,
            SettingsManager.colorBlind,
            SettingsManager.indicators["R$/Km"] == true,
            SettingsManager.indicators["R$/Hora"] == true,
            SettingsManager.indicators["Lucro/H"] == true,
            SettingsManager.indicators["Nota"] == true,
        ).joinToString("|")
    }

    private fun scheduleHide() {
        hideRunnable?.let(handler::removeCallbacks)
        hideRunnable =
            Runnable { hide() }.also { runnable ->
                handler.postDelayed(runnable, (SettingsManager.duration * 1000).toLong())
            }
    }

    private fun attachDragBehavior(view: View) {
        var startX = 0
        var startY = 0
        var touchStartX = 0f
        var touchStartY = 0f
        var hasMoved = false

        view.setOnTouchListener { touchedView, event ->
            val params = currentLayoutParams ?: return@setOnTouchListener false
            val overlay = overlayView ?: return@setOnTouchListener false
            val maxX = max(0, context.resources.displayMetrics.widthPixels - overlay.width)
            val maxY = max(0, context.resources.displayMetrics.heightPixels - overlay.height)

            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    startX = params.x
                    startY = params.y
                    touchStartX = event.rawX
                    touchStartY = event.rawY
                    hasMoved = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val deltaX = (event.rawX - touchStartX).toInt()
                    val deltaY = (event.rawY - touchStartY).toInt()
                    hasMoved = hasMoved || deltaX != 0 || deltaY != 0
                    params.x = (startX + deltaX).coerceIn(0, maxX)
                    params.y = (startY + deltaY).coerceIn(0, maxY)
                    windowManager?.updateViewLayout(overlay, params)
                    true
                }
                MotionEvent.ACTION_UP,
                MotionEvent.ACTION_CANCEL -> {
                    if (hasMoved) {
                        SettingsManager.updateOverlayOffset(context, params.x, params.y)
                    } else {
                        touchedView.performClick()
                    }
                    true
                }
                else -> false
            }
        }
    }

    private fun resolveInitialPosition(
        screenWidth: Int,
        screenHeight: Int,
        overlayWidth: Int,
        overlayHeight: Int,
        margin: Int,
    ): Pair<Int, Int> {
        if (SettingsManager.hasCustomPosition) {
            val customX = SettingsManager.overlayOffsetX.coerceIn(0, max(0, screenWidth - overlayWidth))
            val customY = SettingsManager.overlayOffsetY.coerceIn(0, max(0, screenHeight - overlayHeight))
            return customX to customY
        }

        val topY = dpToPx(40f)
        val centeredX = ((screenWidth - overlayWidth) / 2).coerceAtLeast(0)
        val centeredY = ((screenHeight - overlayHeight) / 2).coerceAtLeast(0)
        val rightX = (screenWidth - overlayWidth - margin).coerceAtLeast(0)
        val bottomY = (screenHeight - overlayHeight - dpToPx(40f)).coerceAtLeast(0)

        return when (SettingsManager.position) {
            1 -> margin to centeredY
            2 -> rightX to centeredY
            3 -> centeredX to bottomY
            else -> centeredX to topY
        }
    }

    private fun formatMetricValue(value: Double): String {
        return String.format("%.2f", value)
    }

    private fun formatDuration(totalMinutes: Int): String {
        val hours = totalMinutes / 60
        val minutes = totalMinutes % 60
        return "${hours}h${minutes.toString().padStart(2, '0')}m"
    }

    private fun spacer(heightDp: Float): View {
        return View(context).apply {
            layoutParams = LinearLayout.LayoutParams(1, dpToPx(heightDp))
        }
    }

    private fun dpToPx(dp: Float): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp,
            context.resources.displayMetrics,
        ).toInt()
    }

    private fun debugLog(message: String) {
        if (isDebugBuild()) {
            Log.d(logTag, message)
        }
    }

    private fun isDebugBuild(): Boolean {
        return (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
    }

    private data class OverlayOfferMetrics(
        val totalKm: Double,
        val totalMinutes: Int,
        val rating: Double,
        val gainPerKm: Double,
        val gainPerHour: Double,
        val profitValue: Double,
    )

    private data class OverlayThemePalette(
        val backgroundColor: Int,
        val primaryTextColor: Int,
        val labelColor: Int,
        val badgeBackgroundColor: Int,
        val badgeTextColor: Int,
    )

    private enum class OverlaySignalStatus {
        GOOD,
        MEDIUM,
        BAD,
    }

    private enum class OverlayIndicator(val overlayLabel: String) {
        GAIN_PER_KM("R$/Km"),
        GAIN_PER_HOUR("R$/Hora"),
        PROFIT_PER_HOUR("Lucro"),
        RATING("Nota"),
    }
}
