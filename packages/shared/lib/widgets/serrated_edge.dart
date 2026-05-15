import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// The Midnight Kitchen signature ornament — a zig-zag serrated edge that
/// replaces the legacy cream scallop. References the paper snack-tray rim.
///
/// Place between two surface regions, e.g. between a hero image and the
/// content area below it.
///
/// ```dart
/// SerratedEdge(color: AppColors.primary) // yellow teeth pointing down
/// SerratedEdge(color: AppColors.surfaceElevated, flip: true)
/// ```
class SerratedEdge extends StatelessWidget {
  const SerratedEdge({
    super.key,
    this.color = AppColors.primary,
    this.height = 10.0,
    this.flip = false,
  });

  final Color color;
  final double height;

  /// When true, the teeth point upward (use when the colour region is below).
  final bool flip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SerratedPainter(color: color, flip: flip),
      ),
    );
  }
}

class _SerratedPainter extends CustomPainter {
  _SerratedPainter({required this.color, required this.flip});

  final Color color;
  final bool flip;

  @override
  void paint(Canvas canvas, Size size) {
    if (flip) canvas.scale(1, -1);
    if (flip) canvas.translate(0, -size.height);

    const toothCount = 50;
    final toothWidth = size.width / toothCount;
    final paint = Paint()..color = color;
    final path = Path()..moveTo(0, 0);

    for (int i = 0; i < toothCount; i++) {
      final x = i * toothWidth;
      path.lineTo(x + toothWidth / 2, size.height);
      path.lineTo(x + toothWidth, 0);
    }

    path
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SerratedPainter old) =>
      old.color != color || old.flip != flip;
}
