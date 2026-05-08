import 'package:freezed_annotation/freezed_annotation.dart';

part 'promotion.freezed.dart';
part 'promotion.g.dart';

/// Doc at `/promotions/{promoId}`. `targetSegment` is a free-form string
/// for now (`"all"`, `"new_customers"`, …) — formalize once segmentation
/// becomes a real feature.
@freezed
class Promotion with _$Promotion {
  const factory Promotion({
    required String id,
    required String title,
    required String body,
    String? imagePath,
    @Default('all') String targetSegment,
    @Default(true) bool active,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) = _Promotion;

  factory Promotion.fromJson(Map<String, dynamic> json) =>
      _$PromotionFromJson(json);
}
