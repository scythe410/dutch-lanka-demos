import 'package:freezed_annotation/freezed_annotation.dart';

part 'address.freezed.dart';
part 'address.g.dart';

/// Subcollection doc at `/users/{uid}/addresses/{addressId}`.
@freezed
class Address with _$Address {
  const factory Address({
    required String id,
    required String label,
    required String line1,
    String? line2,
    required String city,
    String? postalCode,
    double? lat,
    double? lng,
    @Default(false) bool isDefault,
  }) = _Address;

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
}
