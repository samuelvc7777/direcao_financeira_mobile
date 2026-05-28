package com.example.direcao_financeira_mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import kotlin.math.abs

class AppBubbleService : Service() {
    private val bubbleAssetPath = "flutter_assets/assets/images/logo_direcao_financeira2.png"
    private val trafficLightActiveAccentColor = 0xFFE05A5A.toInt()
    private val trafficLightInactiveAccentColor = 0xFF3DDC84.toInt()

    private var windowManager: WindowManager? = null
    private var bubbleView: View? = null
    private var menuView: View? = null
    private var trafficLightActionView: TextView? = null
    private var trafficLightIconView: TextView? = null
    private var recordingActionView: TextView? = null
    private var recordingIconView: TextView? = null
    private var bubbleLayoutParams: WindowManager.LayoutParams? = null
    private var menuLayoutParams: WindowManager.LayoutParams? = null
    private var hiddenForRideOffer = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                setBubbleEnabled(this, false)
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_HIDE_FOR_RIDE_OFFER -> {
                hideForRideOffer()
                return START_NOT_STICKY
            }
            ACTION_RESTORE_AFTER_RIDE_OFFER -> {
                restoreAfterRideOffer()
                return START_NOT_STICKY
            }
            ACTION_START, null -> {
                if (!Settings.canDrawOverlays(this)) {
                    setBubbleEnabled(this, false)
                    stopSelf()
                    return START_NOT_STICKY
                }

                setBubbleEnabled(this, true)
                startForeground(NOTIFICATION_ID, createNotification())
                ensureBubbleVisible()
                isRunning = true
                return START_STICKY
            }
            else -> return START_NOT_STICKY
        }
    }

    override fun onDestroy() {
        removeMenu()
        removeBubble()
        stopForeground(STOP_FOREGROUND_REMOVE)
        isRunning = false
        super.onDestroy()
    }

    private fun ensureBubbleVisible() {
        if (hiddenForRideOffer) {
            return
        }

        if (bubbleView != null) {
            return
        }

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        val bubbleSize = 55.dp

        val iconView =
            ImageView(this).apply {
                runCatching {
                    assets.open(bubbleAssetPath).use { stream ->
                        val bitmap = BitmapFactory.decodeStream(stream)
                        setImageBitmap(bitmap)
                    }
                }.onFailure {
                    setImageResource(R.mipmap.ic_launcher)
                }
                scaleType = ImageView.ScaleType.FIT_CENTER
                setPadding(4.dp, 4.dp, 4.dp, 4.dp)
                layoutParams = WindowManager.LayoutParams(bubbleSize, bubbleSize)
            }

        val params =
            WindowManager.LayoutParams(
                bubbleSize,
                bubbleSize,
                resolveOverlayType(),
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT,
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = 0
                y = 160.dp
            }

        iconView.setOnTouchListener(
            object : View.OnTouchListener {
                private var initialX = 0
                private var initialY = 0
                private var initialTouchX = 0f
                private var initialTouchY = 0f
                private var wasDragged = false

                override fun onTouch(view: View, event: MotionEvent): Boolean {
                    val layoutParams = bubbleLayoutParams ?: return false

                    when (event.action) {
                        MotionEvent.ACTION_DOWN -> {
                            initialX = layoutParams.x
                            initialY = layoutParams.y
                            initialTouchX = event.rawX
                            initialTouchY = event.rawY
                            wasDragged = false
                            return true
                        }

                        MotionEvent.ACTION_MOVE -> {
                            val nextX = initialX + (event.rawX - initialTouchX).toInt()
                            val nextY = initialY + (event.rawY - initialTouchY).toInt()
                            if (abs(nextX - initialX) > 6 || abs(nextY - initialY) > 6) {
                                wasDragged = true
                            }
                            layoutParams.x = nextX
                            layoutParams.y = nextY
                            windowManager?.updateViewLayout(view, layoutParams)
                            return true
                        }

                        MotionEvent.ACTION_UP -> {
                            if (!wasDragged) {
                                toggleMenu()
                            } else {
                                updateMenuPosition()
                            }
                            return true
                        }
                    }

                    return false
                }
            },
        )

        bubbleView = iconView
        bubbleLayoutParams = params
        windowManager?.addView(iconView, params)
    }

    private fun toggleMenu() {
        if (menuView == null) {
            moveBubbleToMenuAnchor()
            showMenu()
            return
        }

        removeMenu()
    }

    private fun showMenu() {
        if (menuView != null) {
            updateMenuPosition()
            return
        }

        val menuContainer =
            LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                background =
                    GradientDrawable().apply {
                        shape = GradientDrawable.RECTANGLE
                        cornerRadius = 24.dp.toFloat()
                        setColor(0xF2142032.toInt())
                        setStroke(1.dp, 0x3DFFFFFF)
                    }
                setPadding(14.dp, 14.dp, 14.dp, 14.dp)
                elevation = 20.dp.toFloat()
            }

        val shiftsAction =
            createMenuActionRow(
                label = getString(R.string.app_bubble_action_shifts),
                iconGlyph = "\uD83D\uDCBC",
                accentColor = 0xFF4F8CFF.toInt(),
                topMargin = 0,
                onClick = { dispatchBubbleAction(ACTION_OPEN_JOURNEY_SHIFTS) },
            )
        menuContainer.addView(shiftsAction.first)

        val ridesAction =
            createMenuActionRow(
                label = getString(R.string.app_bubble_action_rides),
                iconGlyph = "\uD83D\uDE97",
                accentColor = 0xFF2EC7A6.toInt(),
                topMargin = 8.dp,
                onClick = { dispatchBubbleAction(ACTION_OPEN_JOURNEY_RIDES) },
            )
        menuContainer.addView(ridesAction.first)

        val recordingsAction =
            createMenuActionRow(
                label = getString(R.string.app_bubble_action_recordings),
                iconGlyph = "\uD83C\uDFA5",
                accentColor = 0xFFE05A5A.toInt(),
                topMargin = 8.dp,
                onClick = { dispatchBubbleAction(ACTION_OPEN_JOURNEY_RECORDINGS) },
            )
        menuContainer.addView(recordingsAction.first)

        val trafficLightAction =
            createMenuActionRow(
                label = resolveTrafficLightActionLabel(),
                iconGlyph = "\uD83D\uDEA6",
                accentColor = resolveTrafficLightAccentColor(),
                topMargin = 8.dp,
                onClick = { dispatchBubbleAction(ACTION_TOGGLE_TRAFFIC_LIGHT) },
            )
        trafficLightActionView = trafficLightAction.second
        trafficLightIconView = trafficLightAction.third
        menuContainer.addView(trafficLightAction.first)

        val recordingAction =
            createMenuActionRow(
                label = resolveRecordingActionLabel(),
                iconGlyph = "\u25CF",
                accentColor = resolveRecordingAccentColor(),
                topMargin = 8.dp,
                onClick = { dispatchBubbleAction(ACTION_TOGGLE_RECORDING) },
            )
        recordingActionView = recordingAction.second
        recordingIconView = recordingAction.third
        menuContainer.addView(recordingAction.first)

        val params =
            WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                resolveOverlayType(),
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT,
            ).apply {
                gravity = Gravity.TOP or Gravity.START
            }

        menuView = menuContainer
        menuLayoutParams = params
        windowManager?.addView(menuContainer, params)
        updateMenuPosition()
    }

    private fun createMenuActionRow(
        label: String,
        iconGlyph: String,
        accentColor: Int,
        topMargin: Int,
        dismissOnClick: Boolean = true,
        onClick: () -> Unit,
    ): Triple<View, TextView, TextView> {
        val labelView =
            TextView(this).apply {
                text = label
                setTextColor(0xFFFFFFFF.toInt())
                textSize = 14f
                setTypeface(typeface, Typeface.BOLD)
            }

        val iconView =
            TextView(this).apply {
                text = iconGlyph
                gravity = Gravity.CENTER
                textSize = 15f
                background =
                    GradientDrawable().apply {
                        shape = GradientDrawable.RECTANGLE
                        cornerRadius = 14.dp.toFloat()
                        setColor(accentColor)
                    }
                layoutParams =
                    LinearLayout.LayoutParams(28.dp, 28.dp).apply {
                        marginEnd = 12.dp
                    }
            }

        val rowView =
            LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                background =
                    GradientDrawable().apply {
                        shape = GradientDrawable.RECTANGLE
                        cornerRadius = 18.dp.toFloat()
                        setColor(0x1AFFFFFF)
                        setStroke(1.dp, 0x24FFFFFF)
                    }
                setPadding(14.dp, 12.dp, 14.dp, 12.dp)
                addView(iconView)
                addView(labelView)
                setOnClickListener {
                    if (dismissOnClick) {
                        removeMenu()
                    }
                    onClick()
                }
            }

        rowView.layoutParams =
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply {
                this.topMargin = topMargin
            }

        return Triple(rowView, labelView, iconView)
    }

    private fun resolveTrafficLightActionLabel(): String {
        return if (SettingsManager.trafficLightActive) {
            getString(R.string.app_bubble_action_disable_traffic_light)
        } else {
            getString(R.string.app_bubble_action_enable_traffic_light)
        }
    }

    private fun updateTrafficLightActionLabel() {
        trafficLightActionView?.text = resolveTrafficLightActionLabel()
    }

    private fun resolveTrafficLightAccentColor(): Int {
        return if (SettingsManager.trafficLightActive) {
            trafficLightActiveAccentColor
        } else {
            trafficLightInactiveAccentColor
        }
    }

    private fun updateTrafficLightIconAccent() {
        trafficLightIconView?.background =
            GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 14.dp.toFloat()
                setColor(resolveTrafficLightAccentColor())
            }
    }

    private fun updateTrafficLightVisualState() {
        updateTrafficLightActionLabel()
        updateTrafficLightIconAccent()
    }

    private fun resolveRecordingActionLabel(): String {
        return if (RecordingForegroundService.isRecording()) {
            getString(R.string.app_bubble_action_disable_recording)
        } else {
            getString(R.string.app_bubble_action_enable_recording)
        }
    }

    private fun resolveRecordingAccentColor(): Int {
        return if (RecordingForegroundService.isRecording()) {
            0xFFE05A5A.toInt()
        } else {
            0xFF3DDC84.toInt()
        }
    }

    private fun updateRecordingVisualState() {
        recordingActionView?.text = resolveRecordingActionLabel()
        recordingIconView?.background =
            GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 14.dp.toFloat()
                setColor(resolveRecordingAccentColor())
            }
    }

    private fun moveBubbleToMenuAnchor() {
        val view = bubbleView ?: return
        val params = bubbleLayoutParams ?: return
        val screenHeight = resources.displayMetrics.heightPixels
        val bubbleSize = params.height.takeIf { it > 0 } ?: 55.dp

        params.x = 12.dp
        params.y = params.y.coerceIn(48.dp, screenHeight - bubbleSize - 48.dp)
        windowManager?.updateViewLayout(view, params)
    }

    private fun updateMenuPosition() {
        val view = menuView ?: return
        val params = menuLayoutParams ?: return
        val bubbleParams = bubbleLayoutParams ?: return

        view.measure(
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
        )

        params.x = bubbleParams.x + (bubbleView?.width ?: 55.dp) + 16.dp
        params.y = bubbleParams.y
        windowManager?.updateViewLayout(view, params)
    }

    private fun removeMenu() {
        menuView?.let { view ->
            runCatching {
                windowManager?.removeView(view)
            }
        }
        menuView = null
        trafficLightActionView = null
        trafficLightIconView = null
        recordingActionView = null
        recordingIconView = null
        menuLayoutParams = null
    }

    private fun removeBubble() {
        bubbleView?.let { view ->
            runCatching {
                windowManager?.removeView(view)
            }
        }
        bubbleView = null
        bubbleLayoutParams = null
        windowManager = null
    }

    private fun hideForRideOffer() {
        if (hiddenForRideOffer) {
            return
        }

        hiddenForRideOffer = true
        removeMenu()
        removeBubble()
    }

    private fun restoreAfterRideOffer() {
        if (!hiddenForRideOffer) {
            return
        }

        hiddenForRideOffer = false
        if (isBubbleEnabled(this) && Settings.canDrawOverlays(this)) {
            ensureBubbleVisible()
        }
    }

    private fun dispatchBubbleAction(action: String) {
        val launchIntent =
            packageManager.getLaunchIntentForPackage(packageName)?.apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra(EXTRA_BUBBLE_ACTION, action)
            }

        if (launchIntent != null) {
            startActivity(launchIntent)
        }
    }

    private fun createNotification(): Notification {
        createNotificationChannel()

        val launchIntent =
            (packageManager.getLaunchIntentForPackage(packageName)
                ?: Intent(this, MainActivity::class.java)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }

        val contentPendingIntent =
            PendingIntent.getActivity(
                this,
                1001,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentImmutableFlag(),
            )

        val stopIntent =
            Intent(this, AppBubbleService::class.java).apply {
                action = ACTION_STOP
            }

        val stopPendingIntent =
            PendingIntent.getService(
                this,
                1002,
                stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentImmutableFlag(),
            )

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(getString(R.string.app_bubble_notification_title))
            .setContentText(getString(R.string.app_bubble_notification_text))
            .setOngoing(true)
            .setSilent(true)
            .setContentIntent(contentPendingIntent)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                getString(R.string.app_bubble_stop_action),
                stopPendingIntent,
            )
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = getSystemService(NotificationManager::class.java) ?: return
        val channel =
            NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                getString(R.string.app_bubble_notification_channel_name),
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = getString(R.string.app_bubble_notification_channel_description)
                setShowBadge(false)
            }

        manager.createNotificationChannel(channel)
    }

    private fun resolveOverlayType(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
    }

    private fun pendingIntentImmutableFlag(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
    }

    private val Int.dp: Int
        get() = (this * resources.displayMetrics.density).toInt()

    companion object {
        private const val ACTION_START = "com.direcao_financeira.app_bubble.START"
        private const val ACTION_STOP = "com.direcao_financeira.app_bubble.STOP"
        private const val ACTION_HIDE_FOR_RIDE_OFFER =
            "com.direcao_financeira.app_bubble.HIDE_FOR_RIDE_OFFER"
        private const val ACTION_RESTORE_AFTER_RIDE_OFFER =
            "com.direcao_financeira.app_bubble.RESTORE_AFTER_RIDE_OFFER"
        const val ACTION_OPEN_JOURNEY_SHIFTS =
            "com.direcao_financeira.app_bubble.OPEN_JOURNEY_SHIFTS"
        const val ACTION_OPEN_JOURNEY_RIDES =
            "com.direcao_financeira.app_bubble.OPEN_JOURNEY_RIDES"
        const val ACTION_OPEN_JOURNEY_RECORDINGS =
            "com.direcao_financeira.app_bubble.OPEN_JOURNEY_RECORDINGS"
        const val ACTION_TOGGLE_TRAFFIC_LIGHT =
            "com.direcao_financeira.app_bubble.TOGGLE_TRAFFIC_LIGHT"
        const val ACTION_TOGGLE_RECORDING =
            "com.direcao_financeira.app_bubble.TOGGLE_RECORDING"
        private const val NOTIFICATION_CHANNEL_ID = "direcao_financeira_app_bubble"
        private const val NOTIFICATION_ID = 4021
        private const val PREFERENCES_NAME = "direcao_financeira_app_bubble"
        private const val KEY_BUBBLE_ENABLED = "bubble_enabled"
        const val EXTRA_BUBBLE_ACTION = "extra_bubble_action"

        @Volatile
        private var isRunning = false

        fun start(context: Context) {
            val intent =
                Intent(context, AppBubbleService::class.java).apply {
                    action = ACTION_START
                }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            setBubbleEnabled(context, false)
            context.stopService(Intent(context, AppBubbleService::class.java))
        }

        fun isRunning(): Boolean = isRunning

        fun hideForRideOffer(context: Context) {
            if (!isRunning) {
                return
            }

            context.startService(
                Intent(context, AppBubbleService::class.java).apply {
                    action = ACTION_HIDE_FOR_RIDE_OFFER
                },
            )
        }

        fun restoreAfterRideOffer(context: Context) {
            if (!isRunning) {
                return
            }

            context.startService(
                Intent(context, AppBubbleService::class.java).apply {
                    action = ACTION_RESTORE_AFTER_RIDE_OFFER
                },
            )
        }

        fun startIfEnabled(context: Context) {
            if (isBubbleEnabled(context) && Settings.canDrawOverlays(context)) {
                start(context)
            }
        }

        fun createOverlayPermissionIntent(context: Context): Intent {
            return Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:${context.packageName}"),
            ).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        }

        private fun isBubbleEnabled(context: Context): Boolean {
            return context
                .getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
                .getBoolean(KEY_BUBBLE_ENABLED, false)
        }

        private fun setBubbleEnabled(context: Context, enabled: Boolean) {
            context
                .getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_BUBBLE_ENABLED, enabled)
                .apply()
        }
    }
}
