abstract class AppBubbleService {
  Future<bool> isOverlayPermissionGranted();

  Future<void> openOverlayPermissionSettings();

  Future<bool> isBubbleRunning();

  Future<void> startBubble();

  Future<void> stopBubble();
}
