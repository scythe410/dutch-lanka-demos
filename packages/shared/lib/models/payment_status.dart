import 'package:json_annotation/json_annotation.dart';

/// Payment state on an [Order]. Authoritative writer is `payhereNotify`.
enum PaymentStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('paid')
  paid,
  @JsonValue('failed')
  failed,
  @JsonValue('refunded')
  refunded,
}
