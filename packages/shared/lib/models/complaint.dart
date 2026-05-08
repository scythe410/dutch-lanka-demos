import 'package:freezed_annotation/freezed_annotation.dart';

part 'complaint.freezed.dart';
part 'complaint.g.dart';

enum ComplaintStatus {
  @JsonValue('open')
  open,
  @JsonValue('resolved')
  resolved,
}

/// Doc at `/complaints/{complaintId}`.
@freezed
class Complaint with _$Complaint {
  const factory Complaint({
    required String id,
    required String customerId,
    String? orderId,
    required String subject,
    required String body,
    @Default(ComplaintStatus.open) ComplaintStatus status,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) = _Complaint;

  factory Complaint.fromJson(Map<String, dynamic> json) =>
      _$ComplaintFromJson(json);
}
