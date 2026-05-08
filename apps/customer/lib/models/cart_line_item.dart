import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';

/// In-memory cart line. Customer-app-only — never persisted (CLAUDE.md
/// rule 5). At checkout it's converted to an [OrderItem] and sent through
/// the `createOrder` Cloud Function.
class CartLineItem {
  const CartLineItem({
    required this.productId,
    required this.name,
    required this.unitPriceCents,
    required this.qty,
    this.imagePath,
  });

  final String productId;
  final String name;
  final int unitPriceCents;
  final int qty;
  final String? imagePath;

  CartLineItem copyWith({int? qty}) => CartLineItem(
        productId: productId,
        name: name,
        unitPriceCents: unitPriceCents,
        qty: qty ?? this.qty,
        imagePath: imagePath,
      );

  int get lineTotalCents => unitPriceCents * qty;

  factory CartLineItem.fromProduct(Product p, {int qty = 1}) => CartLineItem(
        productId: p.id,
        name: p.name,
        unitPriceCents: p.priceCents,
        qty: qty,
        imagePath: p.imagePath,
      );
}
