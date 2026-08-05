import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final loaded = img.decodeImage(File('assets/images/logo.png').readAsBytesSync())!;

  // Trim the existing white margin baked into the source file so the mark
  // fills the frame, then re-pad with a small, controlled margin only.
  final src = img.trim(loaded, mode: img.TrimMode.topLeftColor);

  final size = src.width > src.height ? src.width : src.height;
  // Small breathing room around the mark (5%).
  final canvasSize = (size * 1.05).round();

  final canvas = img.Image(width: canvasSize, height: canvasSize, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(255, 255, 255, 255));

  final dx = (canvasSize - src.width) ~/ 2;
  final dy = (canvasSize - src.height) ~/ 2;
  img.compositeImage(canvas, src, dstX: dx, dstY: dy);

  File('assets/images/logo_icon_square.png').writeAsBytesSync(img.encodePng(canvas));
  print('Wrote square icon: ${canvasSize}x$canvasSize');
}
