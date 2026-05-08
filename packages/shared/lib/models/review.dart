import 'package:freezed_annotation/freezed_annotation.dart';

part 'review.freezed.dart';
part 'review.g.dart';

/// Subcollection doc at `/products/{productId}/reviews/{reviewId}`.
@freezed
class Review with _$Review {
  const factory Review({
    required String id,
    required String userId,
    required String userName,
    required int rating,
    String? comment,
    DateTime? createdAt,
  }) = _Review;

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
}
