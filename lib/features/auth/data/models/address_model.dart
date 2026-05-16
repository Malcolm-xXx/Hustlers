import '../../domain/entities/address_entity.dart';

class AddressModel {
  final String id;
  final String title;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String country;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.title,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.country,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Address',
      addressLine1: json['address_line_1'] as String? ?? '',
      addressLine2: json['address_line_2'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  AddressEntity toEntity() {
    return AddressEntity(
      id: id,
      title: title,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      state: state,
      country: country,
      isDefault: isDefault,
    );
  }
}
