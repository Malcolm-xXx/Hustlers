import '../../../payments/data/models/payment_models.dart';

// ── API models (server shapes) ─────────────────────────────────────────────────

class StashItemApiModel {
  final String id;
  final String productId;
  final String name;
  final String storeName;
  final String variant; // unit_label from API
  final int unitPrice;
  final int quantity;

  const StashItemApiModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.storeName,
    required this.variant,
    required this.unitPrice,
    required this.quantity,
  });

  factory StashItemApiModel.fromJson(Map<String, dynamic> json) =>
      StashItemApiModel(
        id: json['id'] as String,
        productId: json['product_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        storeName: json['store_name'] as String? ?? '',
        variant: json['unit_label'] as String? ?? '',
        unitPrice: json['unit_price'] as int? ?? 0,
        quantity: json['quantity'] as int? ?? 1,
      );

  StashItem toUiModel() => StashItem(
        id: id,
        name: name,
        storeName: storeName,
        variant: variant,
        unitPrice: unitPrice.toDouble(),
        quantity: quantity,
      );
}

class StashApiModel {
  final String id;
  final List<StashItemApiModel> items;
  final int subtotal;
  final int deliveryFee;
  final int serviceFee;
  final int total;
  final String? deliveryAddress;
  final String? specialInstructions;
  final bool savedForLater;

  const StashApiModel({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.total,
    this.deliveryAddress,
    this.specialInstructions,
    this.savedForLater = false,
  });

  factory StashApiModel.fromJson(Map<String, dynamic> json) => StashApiModel(
        id: json['id'] as String? ?? '',
        items: ((json['items'] as List<dynamic>?) ?? [])
            .map((e) => StashItemApiModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: json['subtotal'] as int? ?? 0,
        deliveryFee: json['delivery_fee'] as int? ?? 0,
        serviceFee: json['service_fee'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
        deliveryAddress: json['delivery_address'] as String?,
        specialInstructions: json['special_instructions'] as String?,
        savedForLater: json['saved_for_later'] as bool? ?? false,
      );
}

// ── UI models ──────────────────────────────────────────────────────────────────

class StashItem {
  final String id;
  final String name;
  final String storeName;
  final String variant;
  final double unitPrice;
  final int quantity;

  const StashItem({
    required this.id,
    required this.name,
    required this.storeName,
    required this.variant,
    required this.unitPrice,
    required this.quantity,
  });

  double get totalPrice => unitPrice * quantity;

  StashItem copyWith({int? quantity}) => StashItem(
        id: id,
        name: name,
        storeName: storeName,
        variant: variant,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
      );

  static const List<StashItem> mockItems = [
    StashItem(
      id: '1',
      name: 'White Garri',
      storeName: 'Ifeanyi Bulk store',
      variant: 'Per Congo',
      unitPrice: 500,
      quantity: 1,
    ),
    StashItem(
      id: '2',
      name: 'Golden Penny Spaghetti',
      storeName: 'Ifeanyi Bulk store',
      variant: '1 Pack',
      unitPrice: 14000,
      quantity: 1,
    ),
    StashItem(
      id: '3',
      name: 'Golden Penny Spread',
      storeName: 'Ifeanyi Bulk store',
      variant: 'Medium size',
      unitPrice: 500,
      quantity: 1,
    ),
    StashItem(
      id: '4',
      name: 'Foreign Rice',
      storeName: 'Ifeanyi Bulk store',
      variant: 'Per Congo',
      unitPrice: 1500,
      quantity: 1,
    ),
    StashItem(
      id: '5',
      name: 'Brown Beans',
      storeName: 'Ifeanyi Bulk store',
      variant: 'Per Congo',
      unitPrice: 1500,
      quantity: 1,
    ),
  ];
}

class SavedCard {
  final String id;
  final String type; // 'mastercard' or 'visa'
  final String lastFour;
  final bool isDefault;
  final bool isSelected;

  const SavedCard({
    required this.id,
    required this.type,
    required this.lastFour,
    this.isDefault = false,
    this.isSelected = false,
  });

  SavedCard copyWith({bool? isSelected}) => SavedCard(
        id: id,
        type: type,
        lastFour: lastFour,
        isDefault: isDefault,
        isSelected: isSelected ?? this.isSelected,
      );

  factory SavedCard.fromSavedCardModel(SavedCardModel model) => SavedCard(
        id: model.id,
        type: model.brand?.toLowerCase() ?? 'visa',
        lastFour: model.lastFourDigits,
        isDefault: model.isDefault,
      );
}

class SavedLocation {
  final String name;
  final String type;
  final String distance;

  const SavedLocation({
    required this.name,
    required this.type,
    required this.distance,
  });

  static const List<SavedLocation> mockLocations = [
    SavedLocation(name: 'Odo-Ona Market', type: 'Traditional Market', distance: '2.3 km'),
    SavedLocation(name: 'Central Market, Bodija', type: 'Central Market', distance: '3.1 km'),
    SavedLocation(name: 'Dugbe Market', type: 'Traditional Market', distance: '4.2 km'),
    SavedLocation(name: 'Spar Supermarket, Jericho', type: 'Supermarket', distance: '1.8 km'),
    SavedLocation(name: 'Shoprite, Ring Road', type: 'Shopping Mall', distance: '5.1 km'),
    SavedLocation(name: 'Campus Provisions Store', type: 'Provisions', distance: '0.5 km'),
  ];
}
