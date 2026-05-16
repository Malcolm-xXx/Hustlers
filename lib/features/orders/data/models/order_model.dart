enum OrderStatus {
  pending,
  accepted,
  shopping,
  delivering, // API value: "delivery"
  done,
  cancelled,
  pendingAdjustment; // API value: "pending_adjustment"

  static OrderStatus fromApiValue(String v) => switch (v) {
        'pending' => OrderStatus.pending,
        'accepted' => OrderStatus.accepted,
        'shopping' => OrderStatus.shopping,
        'delivery' => OrderStatus.delivering,
        'done' => OrderStatus.done,
        'cancelled' => OrderStatus.cancelled,
        'pending_adjustment' => OrderStatus.pendingAdjustment,
        _ => OrderStatus.pending,
      };
}

class OrderItemModel {
  final String id;
  final String name;
  final String quantity;
  final double price;
  final bool isCompleted;
  final bool isCancelled;

  const OrderItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.isCompleted = false,
    this.isCancelled = false,
  });

  OrderItemModel copyWith({
    bool? isCompleted,
    bool? isCancelled,
  }) {
    return OrderItemModel(
      id: id,
      name: name,
      quantity: quantity,
      price: price,
      isCompleted: isCompleted ?? this.isCompleted,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        id: json['id'] as String,
        name: json['name'] as String,
        quantity: '${json['quantity']} ${json['unit_label']}',
        price: (json['price'] as int).toDouble(),
        isCompleted: json['is_delivered'] as bool? ?? false,
      );
}

class OrderModel {
  final String id;
  final String orderNumber;
  final OrderStatus status;
  final String hustlerName;
  final String hustlerRole;
  final String hustlerImageUrl;
  final String location;
  final String deliveryAddress;
  final String eta;
  final List<OrderItemModel> items;
  final double total;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.hustlerName,
    this.hustlerRole = 'Hustler',
    this.hustlerImageUrl = '',
    required this.location,
    required this.deliveryAddress,
    required this.eta,
    required this.items,
    required this.total,
    required this.createdAt,
  });

  int get completedItemCount =>
      items.where((i) => i.isCompleted).length;

  bool get allItemsCompleted =>
      items.every((i) => i.isCompleted || i.isCancelled);

  OrderModel copyWith({
    OrderStatus? status,
    List<OrderItemModel>? items,
  }) {
    return OrderModel(
      id: id,
      orderNumber: orderNumber,
      status: status ?? this.status,
      hustlerName: hustlerName,
      hustlerRole: hustlerRole,
      hustlerImageUrl: hustlerImageUrl,
      location: location,
      deliveryAddress: deliveryAddress,
      eta: eta,
      items: items ?? this.items,
      total: total,
      createdAt: createdAt,
    );
  }

  /// Maps `OrderDetailResponse` (full detail endpoint).
  factory OrderModel.fromDetailJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String,
        orderNumber: '#${json['order_number']}',
        status: OrderStatus.fromApiValue(json['status'] as String),
        hustlerName: json['seller_name'] as String? ?? '',
        hustlerRole: 'Hustler',
        hustlerImageUrl: '',
        location: json['from_address'] as String? ?? '',
        deliveryAddress: json['delivery_address'] as String? ?? '',
        eta: json['eta_minutes'] != null
            ? '${json['eta_minutes']} minutes'
            : '',
        items: ((json['items'] as List<dynamic>?) ?? [])
            .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as int? ?? 0).toDouble(),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  /// Maps `OrderResponse` (list endpoint — no items or pricing detail).
  factory OrderModel.fromSummaryJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String,
        orderNumber: '#${json['order_number']}',
        status: OrderStatus.fromApiValue(json['status'] as String),
        hustlerName: json['seller_name'] as String? ?? '',
        hustlerRole: 'Hustler',
        hustlerImageUrl: '',
        location: json['delivery_address'] as String? ?? '',
        deliveryAddress: json['delivery_address'] as String? ?? '',
        eta: '',
        items: const [],
        total: 0,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  static OrderModel mockOrder = OrderModel(
    id: '1',
    orderNumber: '#8842',
    status: OrderStatus.shopping,
    hustlerName: 'Jude Simon',
    hustlerRole: 'Hustler',
    location: 'Central Market',
    deliveryAddress: 'Hall 4, Room 202',
    eta: '15 minutes',
    total: 8500,
    createdAt: DateTime.now(),
    items: const [
      OrderItemModel(
        id: '1',
        name: 'White Garri',
        quantity: '2 Paint Bucket',
        price: 1500,
      ),
      OrderItemModel(
        id: '2',
        name: 'Foreign Rice',
        quantity: '1 Bag',
        price: 2500,
      ),
      OrderItemModel(
        id: '3',
        name: 'Brown Beans',
        quantity: '3 Kg',
        price: 1800,
      ),
    ],
  );

  static OrderModel mockDeliveredOrder = OrderModel(
    id: '2',
    orderNumber: '#8842',
    status: OrderStatus.done,
    hustlerName: 'Jude Simon',
    hustlerRole: 'Hustler',
    location: 'Central Market',
    deliveryAddress: 'Hall 4, Room 202',
    eta: '15 minutes',
    total: 8500,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    items: const [
      OrderItemModel(
        id: '1',
        name: 'White Garri',
        quantity: '2 Paint Bucket',
        price: 1500,
        isCompleted: true,
      ),
      OrderItemModel(
        id: '2',
        name: 'Foreign Rice',
        quantity: '1 Bag',
        price: 2500,
        isCompleted: true,
      ),
      OrderItemModel(
        id: '3',
        name: 'Brown Beans',
        quantity: '3 Kg',
        price: 1800,
        isCompleted: true,
      ),
    ],
  );
}
