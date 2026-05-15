import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Display tokens use Sora 800 — heavy rounded geometric matching the
/// Midnight Kitchen brand energy (electric-yellow headlines, tight tracking).
/// Body tokens use Inter — clean, high-legibility on dark surfaces.
final TextTheme appTextTheme = TextTheme(
  // ── Display (Sora, heavy) ──────────────────────────────────────────────
  displayLarge: GoogleFonts.sora(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    height: 0.92,
    letterSpacing: -1.2,
  ),
  displayMedium: GoogleFonts.sora(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 0.96,
    letterSpacing: -0.8,
  ),
  headlineLarge: GoogleFonts.sora(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.05,
    letterSpacing: -0.4,
  ),
  headlineSmall: GoogleFonts.sora(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
  ),
  // ── Body (Inter) ─────────────────────────────────────────────────────
  titleMedium: GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
  ),
  titleSmall: GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  ),
  bodyMedium: GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  ),
  bodySmall: GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  ),
  // ── Labels (Sora, bold — CTA text, uppercase via widget) ─────────────
  labelLarge: GoogleFonts.sora(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 1.4,
  ),
  labelSmall: GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 1.6,
  ),
);
