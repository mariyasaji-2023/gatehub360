import 'dart:convert';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Horizontal, swipeable strip of a property's photos with a dot indicator
/// so it reads as scrollable even with the images cut off at the edge.
/// Tapping a photo opens it full-screen, uncropped. Used on both the
/// buyer/tenant-facing property detail page and the owner's property
/// dashboard.
class PropertyPhotoGallery extends StatefulWidget {
  final List<String> images;
  const PropertyPhotoGallery({super.key, required this.images});

  @override
  State<PropertyPhotoGallery> createState() => _PropertyPhotoGalleryState();
}

class _PropertyPhotoGalleryState extends State<PropertyPhotoGallery> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullScreen(int index) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FullScreenPhotoViewer(images: widget.images, initialIndex: index),
      fullscreenDialog: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 200,
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                for (var i = 0; i < images.length; i++)
                  GestureDetector(
                    onTap: () => _openFullScreen(i),
                    child: Image.memory(base64Decode(images[i]), fit: BoxFit.cover, width: double.infinity),
                  ),
              ],
            ),
          ),
        ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < images.length; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.brand : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Full-screen, uncropped viewer opened by tapping a thumbnail in
/// [PropertyPhotoGallery] — swipe between photos, pinch to zoom.
class _FullScreenPhotoViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _FullScreenPhotoViewer({required this.images, required this.initialIndex});

  @override
  State<_FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<_FullScreenPhotoViewer> {
  late final _controller = PageController(initialPage: widget.initialIndex);
  late int _page = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                for (final img in widget.images)
                  InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(child: Image.memory(base64Decode(img), fit: BoxFit.contain)),
                  ),
              ],
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
            if (widget.images.length > 1)
              Positioned(
                top: 16,
                right: 20,
                child: Text(
                  '${_page + 1} / ${widget.images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
