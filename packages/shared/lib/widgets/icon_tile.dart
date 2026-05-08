import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/radius.dart';

/// 48×48 cream rounded-square tile with a Lucide icon centered.
/// Active = orange icon, inactive = silver icon. design.md §6.
///
/// Pass a `LucideIcons.*` constant from the `flutter_lucide` package — but
/// any `IconData` works at the type level.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.active = true,
    this.onTap,
    this.size = 48,
    this.iconSize = 24,
  });

  final IconData icon;
  final bool active;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.iconTile),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: iconSize,
        color: active ? AppColors.primary : AppColors.muted,
      ),
    );

    if (onTap == null) return tile;
    return GestureDetector(onTap: onTap, child: tile);
  }
}
