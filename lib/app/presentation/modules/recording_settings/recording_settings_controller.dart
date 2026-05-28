import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/feedback/app_snackbar.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/recording/recording_settings.dart';
import '../../../routes/app_pages.dart';

class RecordingSettingsController extends GetxController {
  RecordingSettingsController({required this.preferences});

  final AppPreferences preferences;

  final selectedResolution = RecordingResolution.p720.obs;
  final selectedFps = 30.obs;
  final isAudioEnabled = true.obs;
  final selectedCameraFacing = RecordingCameraFacing.front.obs;
  final selectedCompressionProfile = RecordingCompressionProfile.balanced.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  RecordingSettingsSnapshot get currentSettings => RecordingSettingsSnapshot(
    resolution: selectedResolution.value,
    fps: selectedFps.value,
    audioEnabled: isAudioEnabled.value,
    cameraFacing: selectedCameraFacing.value,
    compressionProfile: selectedCompressionProfile.value,
  );

  String get summaryText {
    final audioText = isAudioEnabled.value ? 'com som' : 'sem som';
    return '${selectedResolution.value.label} • ${selectedFps.value} fps • $audioText';
  }

  Future<void> saveSettings() async {
    isLoading.value = true;
    try {
      await currentSettings.save(preferences);
      Get.until((route) => route.settings.name == AppRoutes.settings);
      AppSnackbar.show(
        'Configuração salva',
        'As opções de gravação serão usadas na próxima captura.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (error) {
      AppSnackbar.show(
        'Erro',
        'Não foi possível salvar as configurações de gravação.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      debugPrint('[RecordingSettingsController] Erro ao salvar: $error');
    } finally {
      isLoading.value = false;
    }
  }

  void setResolution(RecordingResolution resolution) {
    selectedResolution.value = resolution;
  }

  void setFps(int fps) {
    selectedFps.value = fps;
  }

  void toggleAudio(bool value) {
    isAudioEnabled.value = value;
  }

  void setCameraFacing(RecordingCameraFacing facing) {
    selectedCameraFacing.value = facing;
  }

  void setCompressionProfile(RecordingCompressionProfile profile) {
    selectedCompressionProfile.value = profile;
  }

  void _loadSettings() {
    final snapshot = RecordingSettingsSnapshot.fromPreferences(preferences);
    selectedResolution.value = snapshot.resolution;
    selectedFps.value = snapshot.fps;
    isAudioEnabled.value = snapshot.audioEnabled;
    selectedCameraFacing.value = snapshot.cameraFacing;
    selectedCompressionProfile.value = snapshot.compressionProfile;
  }
}
