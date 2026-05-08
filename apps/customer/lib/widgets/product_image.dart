import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/products_provider.dart';

/// Resolves a Firebase Storage path to a download URL and renders it. Falls
/// back to a Lucide icon on a Soft Cream tile when the file is missing or
/// the path is null — common during early dev before assets are uploaded.
class ProductImage extends ConsumerWidget {
  const ProductImage({
    super.key,
    this.imagePath,
    this.fallbackIcon = LucideIcons.croissant,
    this.fit = BoxFit.cover,
  });

  final String? imagePath;
  final IconData fallbackIcon;
  final BoxFit fit;

  Widget _placeholder() {
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, size: 56, color: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = imagePath;
    if (path == null || path.isEmpty) return _placeholder();

    final urlAsync = ref.watch(productImageUrlProvider(path));
    return urlAsync.when(
      loading: _placeholder,
      error: (_, _) => _placeholder(),
      data: (url) {
        if (url == null) return _placeholder();
        return Image.network(
          url,
          fit: fit,
          errorBuilder: (_, _, _) => _placeholder(),
        );
      },
    );
  }
}
