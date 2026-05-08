import 'package:flutter/material.dart';

abstract class AppColors {
  static const Color primary = Color(0xFFFFA951);
  static const Color surface = Color(0xFFFAF3E1);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFC0C0C0);
  static const Color onSurface = Color(0xFF000000);

  /// Soft drop-shadow tint — alpha-only black. Centralised so widgets don't
  /// reach for raw hex when adding the standard card/pill shadow.
  static const Color shadow = Color(0x14000000);
}
