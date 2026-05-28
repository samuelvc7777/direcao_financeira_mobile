import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../../domain/entities/help_video_entity.dart';

class HelpVideoFullscreenView extends StatefulWidget {
  const HelpVideoFullscreenView({super.key, required this.video});

  final HelpVideoEntity video;

  @override
  State<HelpVideoFullscreenView> createState() =>
      _HelpVideoFullscreenViewState();
}

class _HelpVideoFullscreenViewState extends State<HelpVideoFullscreenView> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.video.youtubeVideoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: false,
        playsInline: true,
        enableCaption: true,
      ),
    );
    _enterImmersiveVideoMode();
  }

  @override
  void dispose() {
    _controller.close();
    _restoreAppMode();
    super.dispose();
  }

  Future<void> _enterImmersiveVideoMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _restoreAppMode() async {
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final aspectRatio = size.width / size.height;

    return PopScope(
      onPopInvokedWithResult: (_, _) => _restoreAppMode(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: YoutubePlayer(
                  controller: _controller,
                  aspectRatio: aspectRatio,
                  backgroundColor: Colors.black,
                  autoFullScreen: false,
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 10,
                left: 12,
                child: _CloseButton(onTap: () => Navigator.of(context).pop()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.54),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.close_rounded, color: Colors.white),
        ),
      ),
    );
  }
}
