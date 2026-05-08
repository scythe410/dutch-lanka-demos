import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/radius.dart';
import '../theme/spacing.dart';
import '../theme/text_theme.dart';
import 'quantity_stepper.dart';
import 'scalloped_clipper.dart';

/// One ingredient tile in the horizontal "Ingredients" row.
class IngredientChip {
  const IngredientChip({required this.name, this.thumbnail});

  final String name;
  final Widget? thumbnail;
}

/// The signature product-detail layout (design.md §8 `ProductDetailPanel`).
///
/// Top half: cream bg with the floating product photo, optional back +
/// favorite buttons. Bottom half: orange panel with a **scalloped top edge**
/// — the photo dips ~12% into the orange. Inside the orange: title, stars,
/// description, ingredients horizontal scroll. Floating "Add to cart" pill
/// CTA sits at the bottom; quantity stepper sits at the top-right of the
/// orange panel.
class ProductDetailPanel extends StatelessWidget {
  const ProductDetailPanel({
    super.key,
    required this.imageWidget,
    required this.title,
    required this.priceLabel,
    required this.description,
    required this.rating,
    this.ratingMax = 5,
    this.ingredients = const [],
    required this.quantity,
    required this.onQuantityChanged,
    this.favorite = false,
    this.onFavoriteToggle,
    this.onBack,
    this.onAddToCart,
    this.onSeeAllIngredients,
    this.ctaLabel = 'Add to cart',
  });

  final Widget imageWidget;
  final String title;
  final String priceLabel;
  final String description;
  final double rating;
  final int ratingMax;
  final List<IngredientChip> ingredients;

  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  final bool favorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onBack;
  final VoidCallback? onAddToCart;
  final VoidCallback? onSeeAllIngredients;
  final String ctaLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenH = constraints.maxHeight;
        final photoSize = screenH * 0.36;
        final orangeTop = screenH * 0.36;

        return Stack(
          children: [
            // Background: cream above, scalloped orange below.
            Column(
              children: [
                Expanded(
                  flex: 4,
                  child: Container(color: AppColors.surface),
                ),
                Expanded(
                  flex: 6,
                  child: ClipPath(
                    clipper: const ScallopedClipper(
                      direction: ScallopDirection.top,
                    ),
                    child: Container(color: AppColors.primary),
                  ),
                ),
              ],
            ),

            // Floating photo. Sits centered horizontally; vertically it
            // stops short of the orange edge so the bottom 12% dips in.
            Positioned(
              top: orangeTop - photoSize * 0.85,
              left: (constraints.maxWidth - photoSize) / 2,
              width: photoSize,
              height: photoSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(photoSize / 2),
                child: imageWidget,
              ),
            ),

            // Top buttons.
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Row(
                  children: [
                    if (onBack != null)
                      _CircleIconButton(
                        icon: Icons.arrow_back,
                        onTap: onBack,
                        background: AppColors.onPrimary,
                        glyphColor: AppColors.primary,
                      )
                    else
                      const SizedBox(width: 44),
                    const Spacer(),
                    if (onFavoriteToggle != null)
                      _CircleIconButton(
                        icon: favorite ? Icons.favorite : Icons.favorite_border,
                        onTap: onFavoriteToggle,
                        background: AppColors.onPrimary,
                        glyphColor: AppColors.primary,
                      ),
                  ],
                ),
              ),
            ),

            // Orange-panel content, padded so it starts below the photo dip.
            Positioned.fill(
              top: orangeTop + photoSize * 0.18,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.xl,
                    Space.lg,
                    Space.xl,
                    Space.xxxl + Space.xxxl, // leave room for floating CTA
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: appTextTheme.headlineSmall?.copyWith(
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: Space.md),
                            QuantityStepper(
                              value: quantity,
                              onChanged: onQuantityChanged,
                              variant: QuantityStepperVariant.onOrange,
                              minValue: 1,
                            ),
                          ],
                        ),
                        const SizedBox(height: Space.sm),
                        _StarRow(rating: rating, max: ratingMax),
                        const SizedBox(height: Space.lg),
                        Text(
                          'Description',
                          style: appTextTheme.titleMedium
                              ?.copyWith(color: AppColors.onSurface),
                        ),
                        const SizedBox(height: Space.xs),
                        Text(
                          description,
                          style: appTextTheme.bodyMedium
                              ?.copyWith(color: AppColors.onSurface),
                        ),
                        const SizedBox(height: Space.lg),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Ingredients',
                                style: appTextTheme.titleMedium
                                    ?.copyWith(color: AppColors.onSurface),
                              ),
                            ),
                            if (onSeeAllIngredients != null)
                              GestureDetector(
                                onTap: onSeeAllIngredients,
                                child: Text(
                                  'See All',
                                  style: appTextTheme.bodySmall?.copyWith(
                                    color: AppColors.onPrimary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.onPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: Space.sm),
                        if (ingredients.isNotEmpty)
                          SizedBox(
                            height: 80,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: ingredients.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: Space.sm),
                              itemBuilder: (context, i) =>
                                  _IngredientTile(chip: ingredients[i]),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Floating bottom CTA: total price + add-to-cart pill.
            Positioned(
              left: Space.xl,
              right: Space.xl,
              bottom: Space.xl,
              child: SafeArea(
                top: false,
                child: Material(
                  color: AppColors.onPrimary,
                  borderRadius: BorderRadius.circular(AppRadius.buttonPill),
                  child: InkWell(
                    onTap: onAddToCart,
                    borderRadius: BorderRadius.circular(AppRadius.buttonPill),
                    child: Container(
                      height: 56,
                      padding:
                          const EdgeInsets.symmetric(horizontal: Space.xl),
                      child: Row(
                        children: [
                          Text(
                            priceLabel,
                            style: appTextTheme.titleMedium
                                ?.copyWith(color: AppColors.primary),
                          ),
                          const Spacer(),
                          Text(
                            ctaLabel,
                            style: appTextTheme.labelLarge
                                ?.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.background,
    required this.glyphColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color background;
  final Color glyphColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, size: 22, color: glyphColor),
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
          color: AppColors.onPrimary,
        );
      }),
    );
  }
}

class _IngredientTile extends StatelessWidget {
  const _IngredientTile({required this.chip});

  final IngredientChip chip;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.onPrimary,
            borderRadius: BorderRadius.circular(AppRadius.iconTile),
          ),
          alignment: Alignment.center,
          child: chip.thumbnail ??
              const Icon(Icons.eco, color: AppColors.primary),
        ),
        const SizedBox(height: Space.xs),
        SizedBox(
          width: 64,
          child: Text(
            chip.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: appTextTheme.bodySmall?.copyWith(
              color: AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
