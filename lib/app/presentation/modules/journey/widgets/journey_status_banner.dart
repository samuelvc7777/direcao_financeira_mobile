import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../journey_controller.dart';

class JourneyStatusBanner extends GetView<JourneyController> {
  const JourneyStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final message = controller.bannerMessage;
      if (message == null) {
        return const SizedBox.shrink();
      }

      final isOffline = !controller.isOnline;
      final color = isOffline ? AppColors.rose : AppColors.amber;
      final icon = isOffline
          ? Icons.wifi_off_rounded
          : Icons.info_outline_rounded;

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (controller.canOpenTrackingSettings || controller.canRetry)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (controller.canOpenTrackingSettings)
                    TextButton(
                      onPressed: controller.openTrackingSettings,
                      style: TextButton.styleFrom(
                        foregroundColor: color,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 36),
                      ),
                      child: Text(controller.trackingSettingsLabel),
                    ),
                  if (controller.canRetry)
                    TextButton(
                      onPressed: controller.retryJourneyData,
                      style: TextButton.styleFrom(
                        foregroundColor: color,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text('Tentar de novo'),
                    ),
                ],
              ),
          ],
        ),
      );
    });
  }
}
