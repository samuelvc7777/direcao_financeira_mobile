import '../preferences/app_preferences.dart';

enum RecordingResolution {
  p480('480p', '480p'),
  p720('720p', '720p'),
  p1080('1080p', '1080p');

  const RecordingResolution(this.preferenceValue, this.label);

  final String preferenceValue;
  final String label;

  static RecordingResolution fromPreference(String? value) {
    return values.firstWhere(
      (item) => item.preferenceValue == value,
      orElse: () => RecordingResolution.p720,
    );
  }
}

enum RecordingCameraFacing {
  front('front', 'Frontal'),
  back('back', 'Traseira');

  const RecordingCameraFacing(this.preferenceValue, this.label);

  final String preferenceValue;
  final String label;

  static RecordingCameraFacing fromPreference(String? value) {
    return values.firstWhere(
      (item) => item.preferenceValue == value,
      orElse: () => RecordingCameraFacing.front,
    );
  }
}

enum RecordingCompressionProfile {
  economical('economical', 'Economica', 0.82),
  balanced('balanced', 'Equilibrada', 1.0),
  high('high', 'Alta', 1.22);

  const RecordingCompressionProfile(
    this.preferenceValue,
    this.label,
    this.bitrateMultiplier,
  );

  final String preferenceValue;
  final String label;
  final double bitrateMultiplier;

  static RecordingCompressionProfile fromPreference(String? value) {
    return values.firstWhere(
      (item) => item.preferenceValue == value,
      orElse: () => RecordingCompressionProfile.balanced,
    );
  }
}

class RecordingSettingsSnapshot {
  const RecordingSettingsSnapshot({
    required this.resolution,
    required this.fps,
    required this.audioEnabled,
    required this.cameraFacing,
    required this.compressionProfile,
  });

  static const String resolutionKey = 'recording_resolution';
  static const String fpsKey = 'recording_fps';
  static const String audioEnabledKey = 'recording_audio_enabled';
  static const String cameraFacingKey = 'recording_camera_facing';
  static const String compressionProfileKey = 'recording_compression_profile';

  final RecordingResolution resolution;
  final int fps;
  final bool audioEnabled;
  final RecordingCameraFacing cameraFacing;
  final RecordingCompressionProfile compressionProfile;

  factory RecordingSettingsSnapshot.defaults() {
    return const RecordingSettingsSnapshot(
      resolution: RecordingResolution.p720,
      fps: 30,
      audioEnabled: true,
      cameraFacing: RecordingCameraFacing.front,
      compressionProfile: RecordingCompressionProfile.balanced,
    );
  }

  factory RecordingSettingsSnapshot.fromPreferences(
    AppPreferences preferences,
  ) {
    final defaults = RecordingSettingsSnapshot.defaults();
    return RecordingSettingsSnapshot(
      resolution: RecordingResolution.fromPreference(
        preferences.readString(resolutionKey),
      ),
      fps: preferences.readInt(fpsKey) ?? defaults.fps,
      audioEnabled:
          preferences.readBool(audioEnabledKey) ?? defaults.audioEnabled,
      cameraFacing: RecordingCameraFacing.fromPreference(
        preferences.readString(cameraFacingKey),
      ),
      compressionProfile: RecordingCompressionProfile.fromPreference(
        preferences.readString(compressionProfileKey),
      ),
    );
  }

  Future<void> save(AppPreferences preferences) async {
    await preferences.writeString(resolutionKey, resolution.preferenceValue);
    await preferences.writeInt(fpsKey, fps);
    await preferences.writeBool(audioEnabledKey, audioEnabled);
    await preferences.writeString(
      cameraFacingKey,
      cameraFacing.preferenceValue,
    );
    await preferences.writeString(
      compressionProfileKey,
      compressionProfile.preferenceValue,
    );
  }

  Map<String, dynamic> toNativeArguments() {
    return {
      'resolution': resolution.preferenceValue,
      'fps': fps,
      'audioEnabled': audioEnabled,
      'cameraFacing': cameraFacing.preferenceValue,
      'compressionProfile': compressionProfile.preferenceValue,
    };
  }
}
