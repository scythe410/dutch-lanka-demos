import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/radius.dart';
import '../theme/spacing.dart';
import '../theme/text_theme.dart';

/// Dark elevated product card — Midnight Kitchen style.
/// Elevated surface bg, 20px radius, hairline border, product name in yellow,
/// price in near-white, star rating row in muted yellow.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.title,
    required this.priceLabel,
    required this.rating,
    this.imageUrl,
    this.imageWidget,
    this.onTap,
    this.badge,
    this.ratingMax = 5,
  }) : assert(
          imageUrl != null || imageWidget != null,
          'Provide either imageUrl or imageWidget',
        );

  final String title;
  final String priceLabel;
  final double rating;
  final int ratingMax;
  final String? imageUrl;
  final Widget? imageWidget;
  final VoidCallback? onTap;

  /// Optional label shown in a red ribbon (e.g. "HOT", "NEW").
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image area
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.card),
                ),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: imageWidget ??
                          Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: AppColors.surfaceHigh,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                    ),
                    if (badge != null)
                      Positioned(
                        top: Space.sm,
                        left: Space.sm,
                        child: _BadgeChip(label: badge!),
                      ),
                  ],
                ),
              ),
              // Info area
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  Space.md,
                  Space.md,
                  Space.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: appTextTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontSize: 13,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      priceLabel,
                      style: appTextTheme.titleSmall
                          ?.copyWith(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: Space.xs),
                    _StarRow(rating: rating, max: ratingMax),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.sm,
        vertical: Space.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentRed,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: appTextTheme.labelSmall?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating, required this.max});

  final double rating;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (i) {
        final filled = i < rating.floor();
        final half = !filled && i < rating;
        return Icon(
          half
              ? Icons.star_half
              : (filled ? Icons.star : Icons.star_border),
          size: 14,
          color:
              filled || half ? AppColors.primary : AppColors.textTertiary,
        );
      }),
    );
  }
}
