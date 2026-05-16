class AddressRequestModel {
  final String title;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String country;
  final bool isDefault;

  const AddressRequestModel({
    required this.title,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.country,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'address_line_1': addressLine1,
      if (addressLine2 != null) 'address_line_2': addressLine2,
      'city': city,
      'state': state,
      'country': country,
      'is_default': isDefault,
    };
  }
}
