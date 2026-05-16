import 'package:flutter/material.dart';

// ── API model ─────────────────────────────────────────────────────────────────

class NotificationApiModel {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final Map<String, dynamic>? data;

  const NotificationApiModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.data,
  });

  factory NotificationApiModel.fromJson(Map<String, dynamic> json) =>
      NotificationApiModel(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        isRead: json['is_read'] as bool? ?? false,
        data: json['data'] as Map<String, dynamic>?,
      );

  NotificationModel toUiModel() {
    final typeStr = data?['type'] as String? ?? '';
    final type = _inferType(typeStr, title);
    final tab = _inferTab(typeStr, type);
    return NotificationModel(
      id: id,
      type: type,
      tab: tab,
      title: title,
      description: body,
      timeAgo: '',
      isRead: isRead,
      createdAt: DateTime.now(),
    );
  }

  static NotificationType _inferType(String typeStr, String title) =>
      switch (typeStr) {
        'new_hustle' || 'new_hustle_available' => NotificationType.newHustleAvailable,
        'price_adjustment' => NotificationType.priceAdjustment,
        'new_message' => NotificationType.newMessage,
        'new_order' => NotificationType.newOrder,
        'payment_received' => NotificationType.paymentReceived,
        'escrow' || 'funds_in_escrow' => NotificationType.fundsInEscrow,
        'five_star_review' => NotificationType.fiveStarReview,
        'one_star_review' => NotificationType.oneStarReview,
        'order_completed' => NotificationType.orderCompleted,
        _ => _inferTypeFromTitle(title),
      };

  static NotificationType _inferTypeFromTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('payment')) return NotificationType.paymentReceived;
    if (lower.contains('escrow')) return NotificationType.fundsInEscrow;
    if (lower.contains('5-star') || lower.contains('five star')) {
      return NotificationType.fiveStarReview;
    }
    if (lower.contains('1-star') || lower.contains('one star')) {
      return NotificationType.oneStarReview;
    }
    if (lower.contains('order') && lower.contains('complet')) {
      return NotificationType.orderCompleted;
    }
    if (lower.contains('message')) return NotificationType.newMessage;
    if (lower.contains('hustle')) return NotificationType.newHustleAvailable;
    if (lower.contains('price')) return NotificationType.priceAdjustment;
    return NotificationType.newMessage;
  }

  static NotificationTab _inferTab(String typeStr, NotificationType type) =>
      switch (type) {
        NotificationType.paymentReceived ||
        NotificationType.fundsInEscrow ||
        NotificationType.fiveStarReview ||
        NotificationType.oneStarReview ||
        NotificationType.orderCompleted =>
          NotificationTab.account,
        NotificationType.newHustleAvailable ||
        NotificationType.priceAdjustment ||
        NotificationType.newMessage ||
        NotificationType.newOrder =>
          NotificationTab.hustles,
      };
}

enum NotificationType {
  // Hustles tab
  newHustleAvailable,
  priceAdjustment,
  newMessage,
  newOrder,

  // Account tab
  paymentReceived,
  fundsInEscrow,
  fiveStarReview,
  oneStarReview,
  orderCompleted,
}

enum NotificationTab {
  hustles,
  account,
  overdue,
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final NotificationTab tab;
  final String title;
  final String description;
  final String timeAgo;
  final bool isRead;
  final bool needsAction;
  final DateTime createdAt;
  final String? earningText;
  final String? subSection;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.tab,
    required this.title,
    required this.description,
    required this.timeAgo,
    this.isRead = false,
    this.needsAction = false,
    required this.createdAt,
    this.earningText,
    this.subSection,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      type: type,
      tab: tab,
      title: title,
      description: description,
      timeAgo: timeAgo,
      isRead: isRead ?? this.isRead,
      needsAction: needsAction,
      createdAt: createdAt,
      earningText: earningText,
      subSection: subSection,
    );
  }

  Color get iconColor {
    switch (type) {
      case NotificationType.newHustleAvailable:
        return const Color(0xFF4CAF50);
      case NotificationType.priceAdjustment:
        return const Color(0xFFFF9800);
      case NotificationType.newMessage:
        return const Color(0xFF9E9E9E);
      case NotificationType.newOrder:
        return const Color(0xFF26A69A);
      case NotificationType.paymentReceived:
        return const Color(0xFF4CAF50);
      case NotificationType.fundsInEscrow:
        return const Color(0xFF4CAF50);
      case NotificationType.fiveStarReview:
        return const Color(0xFFF6C042);
      case NotificationType.oneStarReview:
        return const Color(0xFFF6C042);
      case NotificationType.orderCompleted:
        return const Color(0xFF2196F3);
    }
  }

  Color get iconBgColor {
    switch (type) {
      case NotificationType.newHustleAvailable:
        return const Color(0xFFE8F5E9);
      case NotificationType.priceAdjustment:
        return const Color(0xFFFFF3E0);
      case NotificationType.newMessage:
        return const Color(0xFFF5F5F5);
      case NotificationType.newOrder:
        return const Color(0xFFE0F2F1);
      case NotificationType.paymentReceived:
        return const Color(0xFFE8F5E9);
      case NotificationType.fundsInEscrow:
        return const Color(0xFFE8F5E9);
      case NotificationType.fiveStarReview:
        return const Color(0xFFFFF8E1);
      case NotificationType.oneStarReview:
        return const Color(0xFFFFF8E1);
      case NotificationType.orderCompleted:
        return const Color(0xFFE3F2FD);
    }
  }

  IconData get iconData {
    switch (type) {
      case NotificationType.newHustleAvailable:
        return Icons.local_shipping_outlined;
      case NotificationType.priceAdjustment:
        return Icons.error_outline;
      case NotificationType.newMessage:
        return Icons.chat_bubble_outline;
      case NotificationType.newOrder:
        return Icons.inventory_2_outlined;
      case NotificationType.paymentReceived:
        return Icons.account_balance_wallet_outlined;
      case NotificationType.fundsInEscrow:
        return Icons.sync;
      case NotificationType.fiveStarReview:
        return Icons.star;
      case NotificationType.oneStarReview:
        return Icons.star;
      case NotificationType.orderCompleted:
        return Icons.check_circle_outline;
    }
  }

  // --- Mock Data ---

  static final List<NotificationModel> mockHustlesNotifications = [
    // From Hustles
    NotificationModel(
      id: 'h1',
      type: NotificationType.newHustleAvailable,
      tab: NotificationTab.hustles,
      title: 'New Hustle Available near you!',
      description:
          'Emmanuel sent a Hustle to Bank Take area, Ibadan.',
      timeAgo: '2m ago',
      needsAction: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      earningText: 'Earn \u20A61,000 on delivery',
      subSection: 'From Hustles',
    ),
    NotificationModel(
      id: 'h2',
      type: NotificationType.priceAdjustment,
      tab: NotificationTab.hustles,
      title: 'Price Adjustment',
      description:
          'Price changed from \u20A6500 to \u20A6600 for White Garri. Would you like to approve?',
      timeAgo: '15m ago',
      needsAction: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      subSection: 'From Hustles',
    ),
    // Your Store Orders
    NotificationModel(
      id: 'h3',
      type: NotificationType.newMessage,
      tab: NotificationTab.hustles,
      title: 'New Message',
      description:
          'Mercy Bolaji sent you a message about order #8843.',
      timeAgo: '1h ago',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      subSection: 'Your Store Orders',
    ),
    NotificationModel(
      id: 'h4',
      type: NotificationType.newOrder,
      tab: NotificationTab.hustles,
      title: 'Rufus Wellens ordered',
      description:
          '3 items have been ordered from your store. Check the details and process the order.',
      timeAgo: '5m ago',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      subSection: 'Your Store Orders',
    ),
    NotificationModel(
      id: 'h5',
      type: NotificationType.newOrder,
      tab: NotificationTab.hustles,
      title: 'Rufus Wellens ordered',
      description:
          '3 items have been ordered from your store. Check the details and process the order.',
      timeAgo: 'Yesterday',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      subSection: 'Your Store Orders',
    ),
  ];

  static final List<NotificationModel> mockAccountNotifications = [
    NotificationModel(
      id: 'a1',
      type: NotificationType.paymentReceived,
      tab: NotificationTab.account,
      title: 'Payment Received',
      description:
          'Your delivery has been confirmed and You earned \u20A61,500 from order #8842. Funds are in your wallet!',
      timeAgo: '1h ago',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      earningText: 'Earn \u20A61,500',
    ),
    NotificationModel(
      id: 'a2',
      type: NotificationType.fundsInEscrow,
      tab: NotificationTab.account,
      title: 'Funds in Escrow',
      description:
          'Order #8845 payment (\u20A62,800) is secured. Complete delivery to release funds.',
      timeAgo: '3h ago',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    NotificationModel(
      id: 'a3',
      type: NotificationType.fiveStarReview,
      tab: NotificationTab.account,
      title: '5-Star Review!',
      description:
          'Michael Chen rated you 5 stars: "Fast delivery and great communication!"',
      timeAgo: 'Yesterday',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotificationModel(
      id: 'a4',
      type: NotificationType.oneStarReview,
      tab: NotificationTab.account,
      title: '1-Star Review!',
      description:
          'Idris Sulaiman rated you 1 star. Check out their review.',
      timeAgo: 'Yesterday',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
    ),
    NotificationModel(
      id: 'a5',
      type: NotificationType.orderCompleted,
      tab: NotificationTab.account,
      title: 'Order Completed',
      description:
          'You successfully delivered order #8841. We are waiting for confirmation from Michael Taiwo.',
      timeAgo: '2 days ago',
      isRead: true,
      needsAction: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  static final List<NotificationModel> mockOverdueNotifications = [
    NotificationModel(
      id: 'o1',
      type: NotificationType.newMessage,
      tab: NotificationTab.overdue,
      title: 'New Message',
      description:
          'Mercy Bolaji sent you a message about order #8843.',
      timeAgo: '1h ago',
      needsAction: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    NotificationModel(
      id: 'o2',
      type: NotificationType.newOrder,
      tab: NotificationTab.overdue,
      title: 'Rufus Wellens ordered',
      description:
          '3 items have been ordered from your store. Check the details and process the order.',
      timeAgo: '5m ago',
      needsAction: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      earningText: 'Earn \u20A61,500 on delivery',
    ),
    NotificationModel(
      id: 'o3',
      type: NotificationType.newOrder,
      tab: NotificationTab.overdue,
      title: 'Rufus Wellens ordered',
      description:
          '3 items have been ordered from your store. Check the details and process the order.',
      timeAgo: 'Yesterday',
      needsAction: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      earningText: 'Earn \u20A61,500 on delivery',
    ),
  ];

  static List<NotificationModel> get allMockNotifications => [
        ...mockHustlesNotifications,
        ...mockAccountNotifications,
        ...mockOverdueNotifications,
      ];
}
