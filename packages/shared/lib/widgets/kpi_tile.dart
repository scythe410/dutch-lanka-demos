import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/radius.dart';
import '../theme/spacing.dart';
import '../theme/text_theme.dart';

/// Manager-app dashboard KPI tile — Midnight Kitchen dark style.
/// Elevated surface bg, 20px radius, hairline border.
/// Label in muted caption. Value in Sora display yellow.
/// Tap chevron when [onTap] is provided.
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.highlight = false,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  /// When true, renders a yellow gradient tile (used for the big sales number).
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: highlight ? null : AppColors.surfaceElevated,
        gradient: highlight
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFD60A), Color(0xFFFFB700)],
              )
            : null,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: highlight ? null : Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: appTextTheme.labelSmall?.copyWith(
              color: highlight
                  ? AppColors.onPrimary.withValues(alpha: 0.6)
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: Space.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: appTextTheme.displayLarge?.copyWith(
                    fontSize: 28,
                    color: highlight ? AppColors.onPrimary : AppColors.primary,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: highlight ? AppColors.onPrimary : AppColors.primary,
                ),
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
