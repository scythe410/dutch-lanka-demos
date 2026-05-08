import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/radius.dart';
import '../theme/spacing.dart';
import '../theme/text_theme.dart';

/// White card per design.md §8 `ProductCard`.
/// Square image at top, 12px top corners; below image: title, orange price,
/// star rating row. 16 padding inside the body, 16 outer radius.
/// Subtle shadow: 8px blur, y-offset 2, 8% black.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.title,
    required this.priceLabel,
    required this.rating,
    this.imageUrl,
    this.imageWidget,
    this.onTap,
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.onPrimary,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.iconTile),
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: imageWidget ??
                      Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.surface,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported,
                              color: AppColors.muted),
                        ),
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: appTextTheme.titleMedium
                          ?.copyWith(color: AppColors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      priceLabel,
                      style: appTextTheme.headlineSmall
                          ?.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: Space.sm),
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
          half ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
          size: 16,
          color: AppColors.primary,
        );
      }),
    );
  }
}
