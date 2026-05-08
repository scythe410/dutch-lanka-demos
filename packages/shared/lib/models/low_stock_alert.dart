import 'package:freezed_annotation/freezed_annotation.dart';

part 'low_stock_alert.freezed.dart';
part 'low_stock_alert.g.dart';

/// Doc at `/lowStockAlerts/{alertId}`. Written by `onOrderCreate`.
@freezed
class LowStockAlert with _$LowStockAlert {
  const factory LowStockAlert({
    required String id,
    required String productId,
    required String productName,
    required int currentStock,
    required int threshold,
    @Default(false) bool acknowledged,
    DateTime? createdAt,
  }) = _LowStockAlert;

  factory LowStockAlert.fromJson(Map<String, dynamic> json) =>
      _$LowStockAlertFromJson(json);
}
