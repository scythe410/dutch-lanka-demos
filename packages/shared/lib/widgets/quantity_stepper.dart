import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_theme.dart';

/// Visual variants for [QuantityStepper] (design.md §8).
/// `onOrange` is used inside an orange panel (white circles, white count).
/// `onCream` is used on the cream canvas (orange circles, black count).
enum QuantityStepperVariant { onOrange, onCream }

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.minValue = 0,
    this.maxValue = 99,
    this.variant = QuantityStepperVariant.onCream,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int minValue;
  final int maxValue;
  final QuantityStepperVariant variant;

  bool get _isOnOrange => variant == QuantityStepperVariant.onOrange;
  Color get _circleColor => _isOnOrange ? AppColors.onPrimary : AppColors.primary;
  Color get _glyphColor => _isOnOrange ? AppColors.primary : AppColors.onPrimary;
  Color get _countColor => _isOnOrange ? AppColors.onPrimary : AppColors.onSurface;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleButton(
          icon: Icons.remove,
          background: _circleColor,
          glyphColor: _glyphColor,
          onTap: value > minValue ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 48,
          child: Center(
            child: Text(
              '$value',
              style: appTextTheme.titleMedium?.copyWith(color: _countColor),
            ),
          ),
        ),
        _CircleButton(
          icon: Icons.add,
          background: _circleColor,
          glyphColor: _glyphColor,
          onTap: value < maxValue ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.background,
    required this.glyphColor,
    required this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color glyphColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: glyphColor),
        ),
      ),
    );
  }
}
