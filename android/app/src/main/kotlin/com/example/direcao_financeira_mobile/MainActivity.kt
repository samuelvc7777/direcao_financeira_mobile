package com.example.direcao_financeira_mobile

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    private val accessibilityChannelName = "com.direcao_financeira/accessibility"
    private val appBubbleChannelName = "com.direcao_financeira/app_bubble"
    private val appBubbleActionsChannelName = "com.direcao_financeira/app_bubble_actions"
    private val locationPermissionsChannelName = "com.direcao_financeira/location_permissions"
    private val invoiceNotificationsChannelName = "com.direcao_financeira/invoice_notifications"
    private val recordingChannelName = "com.direcao_financeira/recording"
    private var backgroundLocationPermissionResult: MethodChannel.Result? = null
    private var recordingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        SettingsManager.initialize(this)
        
        val accessibilityChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, accessibilityChannelName)
        ScreenReaderService.setMethodChannel(accessibilityChannel)
        
        accessibilityChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled(this, ScreenReaderService::class.java))
                }
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "updateSettings" -> {
                    val settings = call.arguments as? Map<String, Any>
                    if (settings != null) {
                        SettingsManager.update(this, settings)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Settings data is null", null)
                    }
                }
                "updateRuntimeState" -> {
                    val state = call.arguments as? Map<String, Any>
                    if (state != null) {
                        SettingsManager.updateRuntimeState(
                            this,
                            trafficLightActive = state["traffic_light_active"] as? Boolean,
                            journeyActive = state["journey_active"] as? Boolean,
                        )
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Runtime state data is null", null)
                    }
                }
                "consumePendingDetectedRides" -> {
                    result.success(ScreenReaderService.consumePendingDetectedRides(this))
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appBubbleChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isOverlayPermissionGranted" -> {
                        result.success(Settings.canDrawOverlays(this))
                    }
                    "openOverlayPermissionSettings" -> {
                        startActivity(AppBubbleService.createOverlayPermissionIntent(this))
                        result.success(true)
                    }
                    "isBubbleRunning" -> {
                        result.success(AppBubbleService.isRunning())
                    }
                    "startBubble" -> {
                        if (!Settings.canDrawOverlays(this)) {
                            result.error(
                                "PERMISSION_DENIED",
                                "A permissao de sobreposicao nao foi concedida.",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        AppBubbleService.start(this)
                        result.success(true)
                    }
                    "stopBubble" -> {
                        AppBubbleService.stop(this)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, locationPermissionsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openBackgroundLocationPermissionSettings" -> {
                        openBackgroundLocationPermissionSettings(result)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, invoiceNotificationsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLocalTimeZoneName" -> result.success(TimeZone.getDefault().id)
                    "openNotificationSettings" -> result.success(openNotificationSettings())
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, recordingChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermissions" -> requestRecordingPermissions(result)
                    "isRecording" -> result.success(RecordingForegroundService.isRecording())
                    "startRecording" -> {
                        if (!RecordingForegroundService.hasRuntimePermissions(this)) {
                            result.error(
                                "PERMISSION_DENIED",
                                "Permissoes de camera e microfone nao foram concedidas.",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        val settings = call.arguments as? Map<String, Any?>
                        val session = RecordingForegroundService.start(this, settings)
                        result.success(session.toMap())
                    }
                    "stopRecording" -> {
                        val session = RecordingForegroundService.stop(this)
                        result.success(session?.toMap())
                    }
                    "openRecording" -> {
                        val args = call.arguments as? Map<*, *>
                        val filePath = args?.get("filePath")?.toString()
                        if (filePath.isNullOrBlank()) {
                            result.error("INVALID_ARGUMENTS", "Arquivo da gravacao ausente.", null)
                            return@setMethodCallHandler
                        }
                        if (openRecordingFile(filePath)) {
                            result.success(true)
                        } else {
                            result.error(
                                "OPEN_FAILED",
                                "Nao foi possivel abrir o arquivo da gravacao.",
                                null,
                            )
                        }
                    }
                    "openAppSettings" -> result.success(openAppDetailsSettings())
                    else -> result.notImplemented()
                }
            }

        AppBubbleActionBridge.attach(
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                appBubbleActionsChannelName,
            ),
        )
        AppBubbleService.startIfEnabled(this)
        handleAppBubbleIntent(intent, deliverImmediately = false)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_BACKGROUND_LOCATION_PERMISSION) {
            backgroundLocationPermissionResult?.success(true)
            backgroundLocationPermissionResult = null
        }
        if (requestCode == REQUEST_RECORDING_PERMISSIONS) {
            val granted = grantResults.isNotEmpty() &&
                grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            recordingPermissionResult?.success(granted)
            recordingPermissionResult = null
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleAppBubbleIntent(intent, deliverImmediately = true)
    }

    private fun handleAppBubbleIntent(
        intent: Intent?,
        deliverImmediately: Boolean,
    ) {
        val rawAction = intent?.getStringExtra(AppBubbleService.EXTRA_BUBBLE_ACTION)
        if (rawAction.isNullOrBlank()) {
            return
        }

        val action =
            when (rawAction) {
                AppBubbleService.ACTION_OPEN_JOURNEY_SHIFTS -> "open_journey_shifts"
                AppBubbleService.ACTION_OPEN_JOURNEY_RIDES -> "open_journey_rides"
                AppBubbleService.ACTION_OPEN_JOURNEY_RECORDINGS -> "open_journey_recordings"
                AppBubbleService.ACTION_TOGGLE_TRAFFIC_LIGHT -> "toggle_traffic_light"
                AppBubbleService.ACTION_TOGGLE_RECORDING -> "toggle_recording"
                else -> null
            }

        if (action != null) {
            val payload = mapOf("action" to action)
            if (deliverImmediately) {
                AppBubbleActionBridge.dispatch(payload)
            } else {
                AppBubbleActionBridge.setPending(payload)
            }
        }
        intent.removeExtra(AppBubbleService.EXTRA_BUBBLE_ACTION)
    }

    private fun isAccessibilityServiceEnabled(context: Context, service: Class<out android.accessibilityservice.AccessibilityService?>): Boolean {
        val expectedComponentName = android.content.ComponentName(context, service)
        val enabledServicesSetting = Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
            ?: return false
        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServicesSetting)
        while (colonSplitter.hasNext()) {
            val componentNameString = colonSplitter.next()
            val enabledService = android.content.ComponentName.unflattenFromString(componentNameString)
            if (enabledService != null && enabledService == expectedComponentName) {
                return true
            }
        }
        return false
    }

    private fun openBackgroundLocationPermissionSettings(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.success(openAppDetailsSettings())
            return
        }

        if (!hasForegroundLocationPermission()) {
            result.success(openAppDetailsSettings())
            return
        }

        if (backgroundLocationPermissionResult != null) {
            result.error(
                "REQUEST_IN_PROGRESS",
                "Ja existe uma solicitacao de localizacao em andamento.",
                null,
            )
            return
        }

        backgroundLocationPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION),
            REQUEST_BACKGROUND_LOCATION_PERMISSION,
        )
    }

    private fun requestRecordingPermissions(result: MethodChannel.Result) {
        if (recordingPermissionResult != null) {
            result.error(
                "REQUEST_IN_PROGRESS",
                "Ja existe uma solicitacao de permissao de gravacao em andamento.",
                null,
            )
            return
        }

        val permissions = mutableListOf(
            Manifest.permission.CAMERA,
            Manifest.permission.RECORD_AUDIO,
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }

        val missing = permissions.filter { permission ->
            ContextCompat.checkSelfPermission(this, permission) !=
                PackageManager.PERMISSION_GRANTED
        }

        if (missing.isEmpty()) {
            result.success(true)
            return
        }

        recordingPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            missing.toTypedArray(),
            REQUEST_RECORDING_PERMISSIONS,
        )
    }

    private fun hasForegroundLocationPermission(): Boolean {
        val fineGranted =
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_FINE_LOCATION,
            ) == PackageManager.PERMISSION_GRANTED
        val coarseGranted =
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_COARSE_LOCATION,
            ) == PackageManager.PERMISSION_GRANTED
        return fineGranted || coarseGranted
    }

    private fun openAppDetailsSettings(): Boolean {
        val intent =
            Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:$packageName"),
            ).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

        return runCatching {
            startActivity(intent)
            true
        }.getOrDefault(false)
    }

    private fun openNotificationSettings(): Boolean {
        val intent =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                    putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                }
            } else {
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.parse("package:$packageName"),
                )
            }.apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

        return runCatching {
            startActivity(intent)
            true
        }.getOrDefault(false)
    }

    private fun openRecordingFile(filePath: String): Boolean {
        val file = File(filePath)
        if (!file.exists()) {
            return false
        }

        val uri = FileProvider.getUriForFile(
            this,
            "$packageName.recording_file_provider",
            file,
        )
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "video/mp4")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        return runCatching {
            startActivity(Intent.createChooser(intent, "Abrir gravacao"))
            true
        }.getOrDefault(false)
    }

    companion object {
        private const val REQUEST_BACKGROUND_LOCATION_PERMISSION = 7301
        private const val REQUEST_RECORDING_PERMISSIONS = 7302
    }
}

private object AppBubbleActionBridge {
    private var channel: MethodChannel? = null
    private var pendingPayload: Map<String, Any?>? = null

    fun attach(methodChannel: MethodChannel) {
        channel = methodChannel
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "consumePendingAction" -> {
                    result.success(pendingPayload)
                    pendingPayload = null
                }
                else -> result.notImplemented()
            }
        }
    }

    fun dispatch(payload: Map<String, Any?>) {
        val currentChannel = channel
        if (currentChannel == null) {
            pendingPayload = payload
            return
        }

        currentChannel.invokeMethod("onBubbleAction", payload)
    }

    fun setPending(payload: Map<String, Any?>) {
        pendingPayload = payload
    }
}
