import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

/// Inline player for a property's walkthrough video (a hosted Cloudinary
/// URL) - tap to play/pause, shown below the photo gallery wherever a
/// property's media is displayed.
class PropertyVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const PropertyVideoPlayer({super.key, required this.videoUrl});

  @override
  State<PropertyVideoPlayer> createState() => _PropertyVideoPlayerState();
}

class _PropertyVideoPlayerState extends State<PropertyVideoPlayer> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _failed = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play());
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: _ready ? _controller.value.aspectRatio : 16 / 9,
        child: Container(
          color: Colors.black,
          child: _failed
              ? const Center(
                  child: Text('Could not load video', style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                )
              : !_ready
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : GestureDetector(
                      onTap: _toggle,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_controller),
                          AnimatedOpacity(
                            opacity: _controller.value.isPlaying ? 0 : 1,
                            duration: const Duration(milliseconds: 150),
                            child: Container(
                              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                              padding: const EdgeInsets.all(14),
                              child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
