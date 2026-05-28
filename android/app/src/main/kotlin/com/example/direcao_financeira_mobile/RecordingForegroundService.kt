package com.example.direcao_financeira_mobile

import android.Manifest
import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.hardware.camera2.CameraCaptureSession
import android.hardware.camera2.CameraDevice
import android.hardware.camera2.CameraManager
import android.media.CamcorderProfile
import android.media.MediaRecorder
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import java.io.File

class RecordingForegroundService : Service() {
    private var cameraThread: HandlerThread? = null
    private var cameraHandler: Handler? = null
    private var mediaRecorder: MediaRecorder? = null
    private var cameraDevice: CameraDevice? = null
    private var captureSession: CameraCaptureSession? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                finishRecording(status = RecordingStatus.COMPLETED)
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_START, null -> {
                if (isRunning || isStarting) {
                    return START_NOT_STICKY
                }

                if (!hasRuntimePermissions(this)) {
                    markFailed("Permissoes de camera e microfone nao concedidas.")
                    stopSelf()
                    return START_NOT_STICKY
                }

                createNotificationChannel()
                val notification = createNotification()
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    startForeground(
                        NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA or
                            ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
                    )
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                }
                startCameraRecording()
                return START_NOT_STICKY
            }
            else -> return START_NOT_STICKY
        }
    }

    override fun onDestroy() {
        finishRecording(status = currentSession?.terminalStatus() ?: RecordingStatus.COMPLETED)
        super.onDestroy()
    }

    @SuppressLint("MissingPermission")
    private fun startCameraRecording() {
        if (isRunning || isStarting) {
            return
        }
        isStarting = true

        val session = currentSession ?: createSession(this).also { currentSession = it }

        try {
            cameraThread = HandlerThread("DFRecordingCamera").also { it.start() }
            cameraHandler = Handler(cameraThread!!.looper)

            val recorder = buildMediaRecorder(session.filePath)
            mediaRecorder = recorder

            val cameraManager = getSystemService(CameraManager::class.java)
            val cameraId = selectCamera(cameraManager, currentConfig.cameraFacing)
                ?: throw IllegalStateException("Nenhuma camera disponivel.")
            val characteristics = cameraManager.getCameraCharacteristics(cameraId)
            val sensorOrientation = characteristics.get(android.hardware.camera2.CameraCharacteristics.SENSOR_ORIENTATION) ?: 270
            recorder.setOrientationHint(sensorOrientation)

            cameraManager.openCamera(
                cameraId,
                object : CameraDevice.StateCallback() {
                    override fun onOpened(camera: CameraDevice) {
                        cameraDevice = camera
                        createRecordingSession(camera, recorder)
                    }

                    override fun onDisconnected(camera: CameraDevice) {
                        camera.close()
                        markFailed("Camera desconectada.")
                        stopSelf()
                    }

                    override fun onError(camera: CameraDevice, error: Int) {
                        camera.close()
                        markFailed("Erro ao abrir camera: $error.")
                        stopSelf()
                    }
                },
                cameraHandler,
            )
        } catch (error: Exception) {
            Log.e(LOG_TAG, "Falha ao iniciar gravacao", error)
            markFailed(error.message ?: "Falha ao iniciar gravacao.")
            stopSelf()
        }
    }

    private fun createRecordingSession(
        camera: CameraDevice,
        recorder: MediaRecorder,
    ) {
        val surface = recorder.surface
        val requestBuilder = camera.createCaptureRequest(CameraDevice.TEMPLATE_RECORD)
            .apply { addTarget(surface) }

        camera.createCaptureSession(
            listOf(surface),
            object : CameraCaptureSession.StateCallback() {
                override fun onConfigured(session: CameraCaptureSession) {
                    captureSession = session
                    try {
                        session.setRepeatingRequest(
                            requestBuilder.build(),
                            null,
                            cameraHandler,
                        )
                        recorder.start()
                        isRunning = true
                        isStarting = false
                    } catch (error: Exception) {
                        Log.e(LOG_TAG, "Falha ao iniciar MediaRecorder", error)
                        markFailed(error.message ?: "Falha ao iniciar gravacao.")
                        stopSelf()
                    }
                }

                override fun onConfigureFailed(session: CameraCaptureSession) {
                    markFailed("Falha ao configurar sessao da camera.")
                    stopSelf()
                }
            },
            cameraHandler,
        )
    }

    @Suppress("DEPRECATION")
    private fun buildMediaRecorder(filePath: String): MediaRecorder {
        val recorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(this)
        } else {
            MediaRecorder()
        }

        val profile = resolveCamcorderProfile(currentConfig.resolution)

        if (currentConfig.audioEnabled) {
            recorder.setAudioSource(MediaRecorder.AudioSource.MIC)
        }
        recorder.setVideoSource(MediaRecorder.VideoSource.SURFACE)
        recorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        recorder.setOutputFile(filePath)
        val bitrate = (profile.videoBitRate * currentConfig.compressionProfile.bitrateMultiplier).toInt()
            .coerceAtLeast(1)
        recorder.setVideoEncodingBitRate(bitrate)
        recorder.setVideoFrameRate(currentConfig.fps.coerceAtLeast(1))
        recorder.setVideoSize(profile.videoFrameWidth, profile.videoFrameHeight)
        recorder.setVideoEncoder(MediaRecorder.VideoEncoder.H264)
        if (currentConfig.audioEnabled) {
            recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
        }
        recorder.prepare()
        return recorder
    }

    private fun selectCamera(
        cameraManager: CameraManager,
        facing: RecordingCameraFacing,
    ): String? {
        return cameraManager.cameraIdList.firstOrNull { cameraId ->
            val characteristics = cameraManager.getCameraCharacteristics(cameraId)
            val lensFacing = characteristics.get(
                android.hardware.camera2.CameraCharacteristics.LENS_FACING,
            )
            when (facing) {
                RecordingCameraFacing.FRONT ->
                    lensFacing == android.hardware.camera2.CameraCharacteristics.LENS_FACING_FRONT
                RecordingCameraFacing.BACK ->
                    lensFacing == android.hardware.camera2.CameraCharacteristics.LENS_FACING_BACK
            }
        } ?: cameraManager.cameraIdList.firstOrNull()
    }

    private fun resolveCamcorderProfile(resolution: RecordingResolution): CamcorderProfile {
        val quality = when (resolution) {
            RecordingResolution.P480 -> CamcorderProfile.QUALITY_480P
            RecordingResolution.P720 -> CamcorderProfile.QUALITY_720P
            RecordingResolution.P1080 -> CamcorderProfile.QUALITY_1080P
        }

        if (CamcorderProfile.hasProfile(quality)) {
            return CamcorderProfile.get(quality)
        }

        if (CamcorderProfile.hasProfile(CamcorderProfile.QUALITY_720P)) {
            return CamcorderProfile.get(CamcorderProfile.QUALITY_720P)
        }

        return CamcorderProfile.get(CamcorderProfile.QUALITY_LOW)
    }

    private fun finishRecording(status: RecordingStatus) {
        if (!isRunning && !isStarting && mediaRecorder == null && cameraDevice == null) {
            return
        }

        runCatching {
            captureSession?.stopRepeating()
            captureSession?.abortCaptures()
        }
        runCatching { mediaRecorder?.stop() }
        runCatching { mediaRecorder?.reset() }
        runCatching { mediaRecorder?.release() }
        runCatching { captureSession?.close() }
        runCatching { cameraDevice?.close() }
        runCatching { cameraThread?.quitSafely() }

        mediaRecorder = null
        captureSession = null
        cameraDevice = null
        cameraThread = null
        cameraHandler = null
        isRunning = false
        isStarting = false
        currentConfig = RecordingConfig.default()
        currentSession = currentSession?.finished(status = currentSession?.terminalStatus() ?: status)
        stopForeground(STOP_FOREGROUND_REMOVE)
    }

    private fun markFailed(message: String) {
        currentSession = currentSession?.finished(
            status = RecordingStatus.FAILED,
            errorMessage = message,
        )
        isRunning = false
        isStarting = false
    }

    private fun createNotification(): Notification {
        val launchIntent =
            (packageManager.getLaunchIntentForPackage(packageName)
                ?: Intent(this, MainActivity::class.java)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }

        val contentPendingIntent =
            PendingIntent.getActivity(
                this,
                1201,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentImmutableFlag(),
            )

        val stopIntent = Intent(this, RecordingForegroundService::class.java).apply {
            action = ACTION_STOP
        }

        val stopPendingIntent =
            PendingIntent.getService(
                this,
                1202,
                stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentImmutableFlag(),
            )

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.presence_video_online)
            .setContentTitle(getString(R.string.recording_notification_title))
            .setContentText(getString(R.string.recording_notification_text))
            .setOngoing(true)
            .setSilent(false)
            .setContentIntent(contentPendingIntent)
            .addAction(
                android.R.drawable.ic_media_pause,
                getString(R.string.recording_stop_action),
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
                getString(R.string.recording_notification_channel_name),
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = getString(R.string.recording_notification_channel_description)
                setShowBadge(false)
            }

        manager.createNotificationChannel(channel)
    }

    private fun pendingIntentImmutableFlag(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
    }

    companion object {
        private const val LOG_TAG = "DFRecordingService"
        private const val ACTION_START = "com.direcao_financeira.recording.START"
        private const val ACTION_STOP = "com.direcao_financeira.recording.STOP"
        private const val NOTIFICATION_CHANNEL_ID = "direcao_financeira_recording"
        private const val NOTIFICATION_ID = 5021

        @Volatile
        private var isRunning = false

        @Volatile
        private var isStarting = false

        @Volatile
        private var currentSession: RecordingSession? = null
        @Volatile
        private var currentConfig: RecordingConfig = RecordingConfig.default()

        fun start(
            context: Context,
            settings: Map<String, Any?>? = null,
        ): RecordingSession {
            currentConfig = RecordingConfig.fromMap(settings)
            val activeSession = currentSession
            if ((isRunning || isStarting) && activeSession != null) {
                return activeSession
            }

            val session = activeSession?.takeIf { it.status == RecordingStatus.RECORDING }
                ?: createSession(context)
            currentSession = session
            val intent = Intent(context, RecordingForegroundService::class.java).apply {
                action = ACTION_START
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }

            return session
        }

        fun stop(context: Context): RecordingSession? {
            if (!isRunning && !isStarting) {
                currentSession =
                    currentSession?.finished(
                        status = currentSession?.terminalStatus() ?: RecordingStatus.COMPLETED,
                    )
                return currentSession
            }

            val intent = Intent(context, RecordingForegroundService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
            return currentSession?.finished(status = RecordingStatus.COMPLETED)
        }

        fun isRecording(): Boolean = isRunning

        fun hasRuntimePermissions(context: Context): Boolean {
            val cameraGranted =
                ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) ==
                    PackageManager.PERMISSION_GRANTED
            val audioGranted =
                ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) ==
                    PackageManager.PERMISSION_GRANTED
            return cameraGranted && audioGranted
        }

        private fun createSession(context: Context): RecordingSession {
            val id = System.currentTimeMillis().toString()
            val directory =
                context.getExternalFilesDir(Environment.DIRECTORY_MOVIES)
                    ?: context.filesDir
            if (!directory.exists()) {
                directory.mkdirs()
            }
            val file = File(directory, "df_recording_$id.mp4")
            return RecordingSession(
                id = id,
                filePath = file.absolutePath,
                startedAtMillis = System.currentTimeMillis(),
            )
        }
    }
}

enum class RecordingStatus {
    RECORDING,
    COMPLETED,
    FAILED,
}

data class RecordingSession(
    val id: String,
    val filePath: String,
    val startedAtMillis: Long,
    val finishedAtMillis: Long? = null,
    val status: RecordingStatus = RecordingStatus.RECORDING,
    val errorMessage: String? = null,
) {
    fun finished(
        status: RecordingStatus,
        errorMessage: String? = null,
    ): RecordingSession {
        val effectiveStatus = terminalStatus() ?: status
        return copy(
            status = effectiveStatus,
            finishedAtMillis = System.currentTimeMillis(),
            errorMessage = errorMessage ?: this.errorMessage,
        )
    }

    fun terminalStatus(): RecordingStatus? {
        return when (status) {
            RecordingStatus.COMPLETED,
            RecordingStatus.FAILED -> status
            RecordingStatus.RECORDING -> null
        }
    }

    fun toMap(): Map<String, Any?> {
        val file = File(filePath)
        val effectiveFinishedAt = finishedAtMillis
        return mapOf(
            "id" to id,
            "status" to status.name,
            "filePath" to filePath,
            "startedAt" to isoString(startedAtMillis),
            "finishedAt" to effectiveFinishedAt?.let(::isoString),
            "durationSeconds" to ((effectiveFinishedAt ?: System.currentTimeMillis()) - startedAtMillis) / 1000,
            "fileSizeBytes" to if (file.exists()) file.length() else 0L,
            "errorMessage" to errorMessage,
        )
    }

    private fun isoString(millis: Long): String {
        return java.time.Instant.ofEpochMilli(millis).toString()
    }
}

private enum class RecordingResolution {
    P480,
    P720,
    P1080;

    companion object {
        fun from(value: Any?): RecordingResolution {
            return when (value?.toString()?.lowercase()) {
                "480p" -> P480
                "1080p" -> P1080
                else -> P720
            }
        }
    }
}

private enum class RecordingCameraFacing {
    FRONT,
    BACK;

    companion object {
        fun from(value: Any?): RecordingCameraFacing {
            return when (value?.toString()?.lowercase()) {
                "back" -> BACK
                else -> FRONT
            }
        }
    }
}

private enum class RecordingCompressionProfile(val bitrateMultiplier: Double) {
    ECONOMICAL(0.82),
    BALANCED(1.0),
    HIGH(1.22);

    companion object {
        fun from(value: Any?): RecordingCompressionProfile {
            return when (value?.toString()?.lowercase()) {
                "economical" -> ECONOMICAL
                "high" -> HIGH
                else -> BALANCED
            }
        }
    }
}

private data class RecordingConfig(
    val resolution: RecordingResolution,
    val fps: Int,
    val audioEnabled: Boolean,
    val cameraFacing: RecordingCameraFacing,
    val compressionProfile: RecordingCompressionProfile,
) {
    companion object {
        fun default(): RecordingConfig {
            return RecordingConfig(
                resolution = RecordingResolution.P720,
                fps = 30,
                audioEnabled = true,
                cameraFacing = RecordingCameraFacing.FRONT,
                compressionProfile = RecordingCompressionProfile.BALANCED,
            )
        }

        fun fromMap(settings: Map<String, Any?>?): RecordingConfig {
            val defaults = default()
            if (settings == null) return defaults
            return RecordingConfig(
                resolution = RecordingResolution.from(settings["resolution"]),
                fps = (settings["fps"] as? Number)?.toInt()?.coerceAtLeast(1)
                    ?: defaults.fps,
                audioEnabled = settings["audioEnabled"] as? Boolean
                    ?: defaults.audioEnabled,
                cameraFacing = RecordingCameraFacing.from(settings["cameraFacing"]),
                compressionProfile = RecordingCompressionProfile.from(
                    settings["compressionProfile"],
                ),
            )
        }
    }
}
