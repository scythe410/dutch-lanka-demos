import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '_press_scale.dart';
import 'primary_button.dart' show ButtonShape;

/// White pill, orange label. Used inside orange contexts (e.g. "Add to cart"
/// on the product detail panel) where a primary orange button would clash.
/// Same dims, radius, and press animation as [PrimaryButton].
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
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: PressScale(
        onTap: onPressed,
        child: ButtonShape(
          label: label,
          icon: icon,
          background: AppColors.onPrimary,
          foreground: AppColors.primary,
          fullWidth: fullWidth,
        ),
      ),
    );
  }
}
