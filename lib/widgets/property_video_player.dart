import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

/// Inline player for a property's walkthrough video (a hosted Cloudinary
/// URL) - tap to play/pause.
///
/// Sizing modes:
/// - Default (neither [size] nor [height] set): sizes itself to the video's
///   own aspect ratio, full width.
/// - [size]: a compact, cropped square - used in the Add/Edit Property
///   form, next to the small square photo thumbnails.
/// - [height]: full width, cropped to a fixed height - used as the last
///   slide of [PropertyPhotoGallery], matching the photo slides around it.
class PropertyVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final double? size;
  final double? height;
  const PropertyVideoPlayer({super.key, required this.videoUrl, this.size, this.height});

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
    final cropped = widget.size != null || widget.height != null;
    final content = Container(
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
                    fit: StackFit.expand,
                    children: [
                      cropped
                          ? FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _controller.value.size.width,
                                height: _controller.value.size.height,
                                child: VideoPlayer(_controller),
                              ),
                            )
                          : VideoPlayer(_controller),
                      AnimatedOpacity(
                        opacity: _controller.value.isPlaying ? 0 : 1,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: widget.size != null ? 30 : 44,
                          shadows: const [Shadow(color: Colors.black54, blurRadius: 10)],
                        ),
                      ),
                    ],
                  ),
                ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(cropped ? 12 : 18),
      child: switch ((widget.size, widget.height)) {
        (final size?, _) => SizedBox(height: size, width: size, child: content),
        (_, final height?) => SizedBox(height: height, width: double.infinity, child: content),
        _ => AspectRatio(aspectRatio: _ready ? _controller.value.aspectRatio : 16 / 9, child: content),
      },
    );
  }
}
