import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/radius.dart';
import '../theme/spacing.dart';
import '../theme/text_theme.dart';
import '_press_scale.dart';

/// Ghost pill button — transparent background, hairline border, near-white label.
/// Used as a softer alternative to [PrimaryButton] (e.g. "Browse Full Menu").
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
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
        child: Container(
          height: 56,
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: Space.xl),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.buttonPill),
            border: Border.all(color: AppColors.lineStrong),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppColors.onSurface),
                const SizedBox(width: Space.sm),
              ],
              Text(
                label.toUpperCase(),
                style: appTextTheme.labelLarge
                    ?.copyWith(color: AppColors.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

