import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

/// Doc at `/products/{productId}`. Per CLAUDE.md, [priceCents] is integer
/// LKR cents — never a float. Display layer divides by 100.
@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required String description,
    required String category,
    required int priceCents,
    String? imagePath,
    @Default(0) int stock,
    @Default(0) int lowStockThreshold,
    @Default(true) bool available,
    @Default(false) bool customizable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
