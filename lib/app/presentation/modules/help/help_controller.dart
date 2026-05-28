import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/feedback/app_snackbar.dart';
import '../../../domain/entities/help_support_contact_entity.dart';
import '../../../domain/entities/help_video_entity.dart';
import '../../../domain/usecases/help_use_cases.dart';

class HelpController extends GetxController {
  HelpController({
    required this.loadHelpVideosUseCase,
    required this.getHelpSupportContactUseCase,
    required this.openHelpSupportContactUseCase,
  });

  final LoadHelpVideosUseCase loadHelpVideosUseCase;
  final GetHelpSupportContactUseCase getHelpSupportContactUseCase;
  final OpenHelpSupportContactUseCase openHelpSupportContactUseCase;

  final isLoading = true.obs;
  final videos = <HelpVideoEntity>[].obs;
  final selectedVideo = Rxn<HelpVideoEntity>();
  final supportContact = Rxn<HelpSupportContactEntity>();
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    final videosResult = await loadHelpVideosUseCase();
    videosResult.fold((failure) => errorMessage.value = failure.message, (
      loadedVideos,
    ) {
      videos.assignAll(loadedVideos);
      selectedVideo.value = loadedVideos.isEmpty ? null : loadedVideos.first;
    });

    final contactResult = await getHelpSupportContactUseCase();
    contactResult.fold(
      (failure) => debugPrint(
        '[HelpController] Erro ao carregar contato: ${failure.message}',
      ),
      (contact) => supportContact.value = contact,
    );

    isLoading.value = false;
  }

  void selectVideo(HelpVideoEntity video) {
    selectedVideo.value = video;
  }

  Future<void> openSupport() async {
    final result = await openHelpSupportContactUseCase();
    result.fold(
      (failure) => _showInfo('WhatsApp', failure.message),
      (_) => _showInfo('WhatsApp', 'Abrindo conversa de suporte.'),
    );
  }

  void _showInfo(String title, String message) {
    AppSnackbar.show(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}
