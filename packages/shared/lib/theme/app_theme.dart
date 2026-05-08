import 'package:flutter/material.dart';

import 'colors.dart';
import 'radius.dart';
import 'spacing.dart';
import 'text_theme.dart';

ThemeData buildAppTheme() {
  final colorScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.primary,
    onSecondary: AppColors.onPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    error: AppColors.onSurface,
    onError: AppColors.onPrimary,
    outline: AppColors.muted,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.surface,
    textTheme: appTextTheme.apply(
      bodyColor: AppColors.onSurface,
      displayColor: AppColors.onSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: appTextTheme.headlineSmall?.copyWith(color: AppColors.onSurface),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.muted,
        disabledForegroundColor: AppColors.onPrimary,
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(horizontal: Space.xl),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.buttonPill),
        ),
        textStyle: appTextTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: appTextTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.buttonPill),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
      hintStyle: appTextTheme.bodyMedium?.copyWith(
        color: AppColors.onSurface.withValues(alpha: 0.5),
      ),
      helperStyle: appTextTheme.bodySmall?.copyWith(color: AppColors.muted),
      errorStyle: appTextTheme.bodySmall?.copyWith(color: AppColors.onSurface),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.muted, thickness: 1),
    iconTheme: const IconThemeData(color: AppColors.primary),
  );
}

final ThemeData appTheme = buildAppTheme();
