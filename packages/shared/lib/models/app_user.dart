import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

/// Mirrored to Firebase Auth custom claims for `role`. Per architecture rule:
/// the claim is the source of truth; this string is a UI convenience.
enum UserRole {
  @JsonValue('customer')
  customer,
  @JsonValue('manager')
  manager,
  @JsonValue('staff')
  staff,
}

/// Doc at `/users/{uid}`.
@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String uid,
    required String email,
    @Default(false) bool emailVerified,
    String? phone,
    required String name,
    String? photoUrl,
    @Default(UserRole.customer) UserRole role,
    @Default([]) List<String> fcmTokens,
    DateTime? createdAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
}
