import 'package:json_annotation/json_annotation.dart';

/// Lifecycle of an [Order]. Stored as snake_case strings in Firestore.
enum OrderStatus {
  @JsonValue('pending_payment')
  pendingPayment,
  @JsonValue('paid')
  paid,
  @JsonValue('preparing')
  preparing,
  @JsonValue('dispatched')
  dispatched,
  @JsonValue('delivered')
  delivered,
  @JsonValue('cancelled')
  cancelled,
}
