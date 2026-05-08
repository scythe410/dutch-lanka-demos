import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final TextTheme appTextTheme = GoogleFonts.workSansTextTheme().copyWith(
  displayLarge: GoogleFonts.workSans(fontSize: 28, fontWeight: FontWeight.w600, height: 1.2),
  headlineSmall: GoogleFonts.workSans(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
  titleMedium: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w500, height: 1.4),
  bodyMedium: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
  bodySmall: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4),
  labelLarge: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w500, height: 1.0),
);
