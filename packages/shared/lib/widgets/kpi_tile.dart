import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/radius.dart';
import '../theme/spacing.dart';
import '../theme/text_theme.dart';

/// Manager-app dashboard tile per design.md §8 `KpiTile`.
/// White background, 16 radius, 16 padding.
/// Top: caption (Caption, black 60%). Center: value (Display, orange).
/// Bottom-right chevron-right when [onTap] is provided.
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: appTextTheme.bodySmall?.copyWith(
              color: AppColors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: Space.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: appTextTheme.displayLarge
                      ?.copyWith(color: AppColors.primary),
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right,
                    size: 20, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return tile;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: tile,
      ),
    );
  }
}
