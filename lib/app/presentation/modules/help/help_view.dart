import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/help_video_entity.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/custom_app_bar.dart';
import 'help_controller.dart';
import 'widgets/help_empty_state.dart';
import 'widgets/help_video_card.dart';
import 'widgets/help_video_fullscreen_view.dart';
import 'widgets/help_whatsapp_fab.dart';

class HelpView extends GetView<HelpController> {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Ajuda',
        subtitle: 'Videos e suporte',
        leadingIcon: Icons.help_outline_rounded,
        showBackButton: true,
      ),
      floatingActionButton: HelpWhatsAppFab(onPressed: controller.openSupport),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingScreen(
            label: 'Carregando ajuda',
            accentColor: AppColors.electricCyan,
          );
        }

        final error = controller.errorMessage.value;
        if (error != null) {
          return _HelpErrorState(message: error, onRetry: controller.load);
        }

        if (controller.videos.isEmpty) {
          return const HelpEmptyState();
        }

        final selected = controller.selectedVideo.value;
        if (selected == null) {
          return const HelpEmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.load,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Todos os videos',
                            style: TextStyle(
                              color: context.theme.colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...controller.videos.map(
                            (video) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: HelpVideoCard(
                                video: video,
                                isSelected: video.id == selected.id,
                                onTap: () {
                                  controller.selectVideo(video);
                                  _openVideo(context, video);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _openVideo(BuildContext context, HelpVideoEntity video) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HelpVideoFullscreenView(video: video),
        fullscreenDialog: true,
      ),
    );
  }
}

class _HelpErrorState extends StatelessWidget {
  const _HelpErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 52, color: AppColors.rose),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
