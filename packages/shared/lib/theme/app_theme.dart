import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'radius.dart';
import 'spacing.dart';
import 'text_theme.dart';

ThemeData buildAppTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.accentOrange,
    onSecondary: AppColors.onPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    error: AppColors.accentRed,
    onError: AppColors.onSurface,
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
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: appTextTheme.headlineSmall?.copyWith(
        color: AppColors.onSurface,
      ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.buttonPill),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceElevated,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md,
      ),
      hintStyle: appTextTheme.bodyMedium?.copyWith(
        color: AppColors.textTertiary,
      ),
      helperStyle: appTextTheme.bodySmall?.copyWith(color: AppColors.muted),
      errorStyle:
          appTextTheme.bodySmall?.copyWith(color: AppColors.accentRed),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.lineStrong, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.lineStrong, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.accentRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
    ),
    iconTheme: const IconThemeData(color: AppColors.onSurface),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceElevated,
      selectedColor: AppColors.primary,
      labelStyle:
          appTextTheme.labelSmall?.copyWith(color: AppColors.onSurface),
      side: const BorderSide(color: AppColors.lineStrong),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.buttonPill),
      ),
    ),
  );
}

final ThemeData appTheme = buildAppTheme();
