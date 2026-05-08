import 'package:freezed_annotation/freezed_annotation.dart';

import 'order_item.dart';
import 'order_status.dart';
import 'payment_status.dart';

part 'order.freezed.dart';
part 'order.g.dart';

/// Embedded delivery address snapshot on an [Order].
@freezed
class DeliveryAddress with _$DeliveryAddress {
  const factory DeliveryAddress({
    required String line1,
    String? line2,
    required String city,
    String? postalCode,
    double? lat,
    double? lng,
  }) = _DeliveryAddress;

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) =>
      _$DeliveryAddressFromJson(json);
}

/// Doc at `/orders/{orderId}`. All money fields are integer LKR cents per
/// CLAUDE.md — never floats.
@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required String customerId,
    required List<OrderItem> items,
    required int subtotalCents,
    required int deliveryFeeCents,
    required int totalCents,
    required DeliveryAddress deliveryAddress,
    required String paymentMethod,
    @Default(PaymentStatus.pending) PaymentStatus paymentStatus,
    String? payherePaymentId,
    @Default(OrderStatus.pendingPayment) OrderStatus status,
    String? assignedDeliveryUid,
    DateTime? createdAt,
    DateTime? paidAt,
    DateTime? dispatchedAt,
    DateTime? deliveredAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}
