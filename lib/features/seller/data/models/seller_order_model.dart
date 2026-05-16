import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

// ── API status mapping ────────────────────────────────────────────────────────

SellerOrderStatus sellerOrderStatusFromApi(String? v) => switch (v) {
      'accepted' => SellerOrderStatus.accepted,
      'inprogress' => SellerOrderStatus.shopping,
      'arriving' => SellerOrderStatus.delivering,
      'delivered' => SellerOrderStatus.done,
      _ => SellerOrderStatus.accepted,
    };

enum SellerOrderStatus {
  accepted,
  shopping,
  delivering,
  done,
}

extension SellerOrderStatusX on SellerOrderStatus {
  String get label {
    switch (this) {
      case SellerOrderStatus.accepted:
        return 'Accepted';
      case SellerOrderStatus.shopping:
        return 'In Progress';
      case SellerOrderStatus.delivering:
        return 'On the way';
      case SellerOrderStatus.done:
        return 'Completed';
    }
  }

  Color get badgeColor {
    switch (this) {
      case SellerOrderStatus.accepted:
        return AppColors.verifiedGreen;
      case SellerOrderStatus.shopping:
        return AppColors.primary600;
      case SellerOrderStatus.delivering:
        return AppColors.verifiedGreen;
      case SellerOrderStatus.done:
        return AppColors.textGrey;
    }
  }

  Color get badgeBgColor {
    switch (this) {
      case SellerOrderStatus.accepted:
        return const Color(0xFFE8F5E9);
      case SellerOrderStatus.shopping:
        return const Color(0xFFFFF8E1);
      case SellerOrderStatus.delivering:
        return const Color(0xFFE8F5E9);
      case SellerOrderStatus.done:
        return const Color(0xFFF5F5F5);
    }
  }

  int get stepIndex {
    switch (this) {
      case SellerOrderStatus.accepted:
        return 0;
      case SellerOrderStatus.shopping:
        return 1;
      case SellerOrderStatus.delivering:
        return 2;
      case SellerOrderStatus.done:
        return 3;
    }
  }

  String get stepLabel {
    switch (this) {
      case SellerOrderStatus.accepted:
        return 'Accepted';
      case SellerOrderStatus.shopping:
        return 'Shopping';
      case SellerOrderStatus.delivering:
        return 'Delivering';
      case SellerOrderStatus.done:
        return 'Done';
    }
  }
}

class SellerOrderItem {
  final String id;
  final String name;
  final String quantityUnit;
  final double price;
  final bool isChecked;

  const SellerOrderItem({
    required this.id,
    required this.name,
    required this.quantityUnit,
    required this.price,
    this.isChecked = false,
  });

  SellerOrderItem copyWith({bool? isChecked}) {
    return SellerOrderItem(
      id: id,
      name: name,
      quantityUnit: quantityUnit,
      price: price,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  factory SellerOrderItem.fromJson(Map<String, dynamic> json) =>
      SellerOrderItem(
        id: json['id'] as String,
        name: json['name'] as String,
        quantityUnit: '${json['quantity']} ${json['unit_label']}',
        price: (json['price'] as int).toDouble(),
        isChecked: json['is_delivered'] as bool? ?? false,
      );
}

class SellerOrderModel {
  final String id;
  final String orderNumber;
  final String buyerName;
  final String buyerAvatarUrl;
  final String route;
  final SellerOrderStatus status;
  final List<SellerOrderItem> items;
  final int? deliveryTimeMinutes;
  final double commissionRate;

  const SellerOrderModel({
    required this.id,
    required this.orderNumber,
    required this.buyerName,
    this.buyerAvatarUrl = '',
    required this.route,
    required this.status,
    required this.items,
    this.deliveryTimeMinutes,
    this.commissionRate = 0.15,
  });

  double get orderTotal =>
      items.fold(0.0, (sum, item) => sum + item.price);

  double get commission => (orderTotal * commissionRate).roundToDouble();

  int get checkedCount => items.where((i) => i.isChecked).length;

  SellerOrderModel copyWith({
    SellerOrderStatus? status,
    List<SellerOrderItem>? items,
    int? deliveryTimeMinutes,
  }) {
    return SellerOrderModel(
      id: id,
      orderNumber: orderNumber,
      buyerName: buyerName,
      buyerAvatarUrl: buyerAvatarUrl,
      route: route,
      status: status ?? this.status,
      items: items ?? this.items,
      deliveryTimeMinutes: deliveryTimeMinutes ?? this.deliveryTimeMinutes,
      commissionRate: commissionRate,
    );
  }

  /// Maps `SellerOrderDetailResponse` (full detail endpoint).
  factory SellerOrderModel.fromDetailJson(Map<String, dynamic> json) {
    final from = json['from_address'] as String? ?? '';
    final to = json['delivery_address'] as String? ?? '';
    return SellerOrderModel(
      id: json['id'] as String? ?? '',
      orderNumber: '#${json['order_number']}',
      buyerName: json['buyer_name'] as String? ?? '',
      buyerAvatarUrl: json['buyer_profile_image_url'] as String? ?? '',
      route: '$from → $to',
      status: sellerOrderStatusFromApi(json['seller_order_status'] as String?),
      items: ((json['items'] as List<dynamic>?) ?? [])
          .map((e) => SellerOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      commissionRate: 0.15,
    );
  }

  /// Maps `SellerOrderResponse` (list endpoint — no items detail).
  factory SellerOrderModel.fromSummaryJson(Map<String, dynamic> json) {
    final from = json['from_address'] as String? ?? '';
    final to = json['delivery_address'] as String? ?? '';
    return SellerOrderModel(
      id: json['id'] as String,
      orderNumber: '#${json['order_number']}',
      buyerName: json['buyer_name'] as String? ?? '',
      buyerAvatarUrl: json['buyer_profile_image_url'] as String? ?? '',
      route: '$from → $to',
      status: sellerOrderStatusFromApi(json['seller_order_status'] as String?),
      items: const [],
      commissionRate: 0.15,
    );
  }

  static final List<SellerOrderModel> mockOrders = [
    SellerOrderModel(
      id: '1',
      orderNumber: '#8842',
      buyerName: 'Rufus Wellens',
      buyerAvatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      route: 'Central Market \u2192 Hall 4, Room 202',
      status: SellerOrderStatus.accepted,
      items: const [
        SellerOrderItem(
          id: 'i1',
          name: 'White Garri',
          quantityUnit: '2 Paint Bucket',
          price: 1500,
        ),
        SellerOrderItem(
          id: 'i2',
          name: 'Foreign Rice',
          quantityUnit: '1 Bag',
          price: 2500,
        ),
        SellerOrderItem(
          id: 'i3',
          name: 'Brown Beans',
          quantityUnit: '3 Kg',
          price: 1800,
        ),
      ],
    ),
    SellerOrderModel(
      id: '2',
      orderNumber: '#8841',
      buyerName: 'Kofo Dua',
      route: 'Bodija Market \u2192 UI Campus',
      status: SellerOrderStatus.shopping,
      deliveryTimeMinutes: 30,
      items: const [
        SellerOrderItem(
          id: 'i4',
          name: 'Local Rice',
          quantityUnit: '1 Bag',
          price: 2000,
          isChecked: true,
        ),
        SellerOrderItem(
          id: 'i5',
          name: 'Palm Oil',
          quantityUnit: '2 Litres',
          price: 1200,
        ),
      ],
    ),
    SellerOrderModel(
      id: '3',
      orderNumber: '#8840',
      buyerName: 'Taiwo Musa',
      route: 'Dugbe Market \u2192 Mokola',
      status: SellerOrderStatus.delivering,
      deliveryTimeMinutes: 60,
      items: const [
        SellerOrderItem(
          id: 'i6',
          name: 'White Garri',
          quantityUnit: '1 Paint Bucket',
          price: 800,
          isChecked: true,
        ),
        SellerOrderItem(
          id: 'i7',
          name: 'Brown Beans',
          quantityUnit: '2 Kg',
          price: 1200,
          isChecked: true,
        ),
      ],
    ),
  ];
}
