import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Canvas / surfaces ─────────────────────────────────────────────────────
  static const Color surface = Color(0xFF0B0B0E);          // scaffold / app bg
  static const Color surfaceElevated = Color(0xFF15151A);  // raised cards
  static const Color surfaceHigh = Color(0xFF1D1D24);      // nested / hover

  // ── Primary — Electric Yellow ─────────────────────────────────────────────
  static const Color primary = Color(0xFFFFD60A);
  static const Color onPrimary = Color(0xFF0A0A08);        // dark text on yellow

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFFF6F5F1);        // near-white
  static const Color textSecondary = Color(0x9EF6F5F1);    // 62 % white
  static const Color textTertiary = Color(0x61F6F5F1);     // 38 % white

  // ── Accents ───────────────────────────────────────────────────────────────
  static const Color accentRed = Color(0xFFE5002B);        // HOT ribbon badges
  static const Color accentOrange = Color(0xFFFFA951);     // legacy bakery orange
  static const Color success = Color(0xFF2EE16A);
  static const Color info = Color(0xFF3B9DFF);

  // ── Borders / hairlines ───────────────────────────────────────────────────
  static const Color line = Color(0x14FFFFFF);             // 8 % white
  static const Color lineStrong = Color(0x29FFFFFF);       // 16 % white
  static const Color muted = Color(0xFF888888);

  // ── Shadows ───────────────────────────────────────────────────────────────
  static const Color shadow = Color(0x66000000);
}
