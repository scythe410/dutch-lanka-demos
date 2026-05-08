import 'package:flutter/material.dart';

enum ScallopDirection { top, bottom }

class ScallopedClipper extends CustomClipper<Path> {
  const ScallopedClipper({
    this.direction = ScallopDirection.top,
    this.amplitude = 12.0,
    this.period = 40.0,
  });

  final ScallopDirection direction;
  final double amplitude;
  final double period;

  @override
  Path getClip(Size size) {
    final path = Path();
    final isTop = direction == ScallopDirection.top;
    final edgeY = isTop ? amplitude : size.height - amplitude;

    // Bumps point inward (away from the clipped child) so the cream/orange
    // boundary forms the fluted-tart silhouette: when orange is below
    // (direction=top), the bumps push downward into the orange region.
    final bumpDir = isTop ? 1.0 : -1.0;

    if (isTop) {
      path.moveTo(0, edgeY);
    } else {
      path.moveTo(0, 0);
      path.lineTo(0, edgeY);
    }

    final bumpCount = (size.width / period).ceil();
    final step = size.width / bumpCount;
    for (var i = 0; i < bumpCount; i++) {
      final startX = i * step;
      final controlX = startX + step / 2;
      final endX = startX + step;
      path.quadraticBezierTo(
        controlX,
        edgeY + bumpDir * amplitude * 2,
        endX,
        edgeY,
      );
    }

    if (isTop) {
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    } else {
      path.lineTo(size.width, 0);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant ScallopedClipper oldClipper) {
    return oldClipper.direction != direction ||
        oldClipper.amplitude != amplitude ||
        oldClipper.period != period;
  }
}
