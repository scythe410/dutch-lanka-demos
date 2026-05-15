import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/radius.dart';
import '../theme/spacing.dart';
import '../theme/text_theme.dart';
import '_press_scale.dart';

/// Primary CTA — electric-yellow pill, dark label, uppercase Sora.
/// Height 56, radius 28, h-padding 24, optional leading icon (20px), 8px gap.
/// Disabled = 40 % opacity. Tap scale 0.97 over 120ms.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed != null ? 1.0 : 0.4,
      child: PressScale(
        onTap: onPressed,
        child: _ButtonBody(
          label: label,
          icon: icon,
          background: AppColors.primary,
          foreground: AppColors.onPrimary,
          fullWidth: fullWidth,
        ),
      ),
    );
  }
}

class _ButtonBody extends StatelessWidget {
  const _ButtonBody({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.fullWidth,
  });

  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: Space.xl),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.buttonPill),
        boxShadow: background == AppColors.primary
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: foreground),
            const SizedBox(width: Space.sm),
          ],
          Text(
            label.toUpperCase(),
            style: appTextTheme.labelLarge?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

/// Exposed so [SecondaryButton] and other callers can compose the same shape.
class ButtonShape extends StatelessWidget {
  const ButtonShape({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return _ButtonBody(
      label: label,
      icon: icon,
      background: background,
      foreground: foreground,
      fullWidth: fullWidth,
    );
  }
}
