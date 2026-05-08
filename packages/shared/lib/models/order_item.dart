import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_item.freezed.dart';
part 'order_item.g.dart';

/// Embedded inside an [Order] — denormalized snapshot of a product at the
/// moment of checkout (so historical orders don't break when a product is
/// renamed or repriced).
@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String productId,
    required String name,
    required int qty,
    required int unitPriceCents,
    Map<String, dynamic>? customizations,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);
}
