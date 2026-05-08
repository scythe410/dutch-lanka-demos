import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/radius.dart';
import '../theme/spacing.dart';
import '../theme/text_theme.dart';
import '_press_scale.dart';

/// Dominant CTA — orange pill, white label. design.md §8 spec:
/// height 56, radius 28, h-padding 24, optional 20px leading icon, 8px gap,
/// disabled = 40% opacity, tap scale 0.97 over 100ms.
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
    final enabled = onPressed != null;
    final body = _ButtonBody(
      label: label,
      icon: icon,
      background: AppColors.primary,
      foreground: AppColors.onPrimary,
      fullWidth: fullWidth,
    );

    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: PressScale(
        onTap: onPressed,
        child: body,
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
    final content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: Space.sm),
        ],
        Text(
          label,
          style: appTextTheme.labelLarge?.copyWith(color: foreground),
        ),
      ],
    );

    return Container(
      height: 56,
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: Space.xl),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.buttonPill),
      ),
      alignment: Alignment.center,
      child: content,
    );
  }
}

/// Internal body shape exposed so [SecondaryButton] can reuse it.
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
