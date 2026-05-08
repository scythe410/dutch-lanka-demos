import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Renders the brand-coloured map pins. We don't ship sprite PNGs because
/// the design's marker shape (round pin, lucide icon, our palette) doesn't
/// exist as a stock asset — drawing them on a canvas keeps a single source
/// of truth and survives palette changes.
class MapMarkers {
  static BitmapDescriptor? _bakery;
  static BitmapDescriptor? _courier;

  /// Cream pin with an orange chef-hat icon — the bakery's fixed origin.
  static Future<BitmapDescriptor> bakery() async {
    return _bakery ??= await _build(
      background: AppColors.surface,
      foreground: AppColors.primary,
      icon: LucideIcons.cake_slice,
    );
  }

  /// Orange pin with a white bike icon — the moving courier.
  static Future<BitmapDescriptor> courier() async {
    return _courier ??= await _build(
      background: AppColors.primary,
      foreground: AppColors.onPrimary,
      icon: LucideIcons.bike,
    );
  }

  static Future<BitmapDescriptor> _build({
    required Color background,
    required Color foreground,
    required IconData icon,
  }) async {
    const size = 96.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(const Offset(size / 2, size / 2 + 4), size / 2 - 6, shadow);

    final fill = Paint()..color = background;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 6, fill);

    final ring = Paint()
      ..color = foreground.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 6, ring);

    final iconPainter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 40,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: foreground,
        ),
      )
      ..layout();
    iconPainter.paint(
      canvas,
      Offset(
        (size - iconPainter.width) / 2,
        (size - iconPainter.height) / 2,
      ),
    );

    final image = await recorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      Uint8List.view(bytes!.buffer),
    );
  }
}
