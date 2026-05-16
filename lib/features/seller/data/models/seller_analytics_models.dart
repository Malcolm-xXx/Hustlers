class SellerInsightModel {
  final String range;
  final String totalEarnings;
  final String earningsChangePct;
  final int totalOrders;
  final String ordersChangePct;
  final int totalHustles;
  final String hustlesChangePct;
  final String avgRating;
  final int avgDeliveryMinutes;
  final String successRate;

  const SellerInsightModel({
    required this.range,
    required this.totalEarnings,
    required this.earningsChangePct,
    required this.totalOrders,
    required this.ordersChangePct,
    required this.totalHustles,
    required this.hustlesChangePct,
    required this.avgRating,
    required this.avgDeliveryMinutes,
    required this.successRate,
  });

  factory SellerInsightModel.fromJson(Map<String, dynamic> json) {
    return SellerInsightModel(
      range: json['range'] as String,
      totalEarnings: json['total_earnings'] as String,
      earningsChangePct: json['earnings_change_pct'] as String,
      totalOrders: json['total_orders'] as int,
      ordersChangePct: json['orders_change_pct'] as String,
      totalHustles: json['total_hustles'] as int,
      hustlesChangePct: json['hustles_change_pct'] as String,
      avgRating: json['avg_rating'] as String,
      avgDeliveryMinutes: json['avg_delivery_minutes'] as int,
      successRate: json['success_rate'] as String,
    );
  }
}

class TopListingModel {
  final Map<String, dynamic> product; // Keeping as map for now as it's dynamic in spec
  final String grossSalesAmount;
  final int viewsCount;
  final int ordersCount;

  const TopListingModel({
    required this.product,
    required this.grossSalesAmount,
    required this.viewsCount,
    required this.ordersCount,
  });

  factory TopListingModel.fromJson(Map<String, dynamic> json) {
    return TopListingModel(
      product: json['product'] as Map<String, dynamic>,
      grossSalesAmount: json['gross_sales_amount'] as String,
      viewsCount: json['views_count'] as int,
      ordersCount: json['orders_count'] as int,
    );
  }
}

class HotZoneModel {
  final Map<String, dynamic> location;
  final int ordersCount;
  final String changePct;

  const HotZoneModel({
    required this.location,
    required this.ordersCount,
    required this.changePct,
  });

  factory HotZoneModel.fromJson(Map<String, dynamic> json) {
    return HotZoneModel(
      location: json['location'] as Map<String, dynamic>,
      ordersCount: json['orders_count'] as int,
      changePct: json['change_pct'] as String,
    );
  }
}

class ServiceAreaOpportunityModel {
  final Map<String, dynamic> location;
  final int weeklyOrders;
  final int customersCount;
  final String avgOrderAmount;

  const ServiceAreaOpportunityModel({
    required this.location,
    required this.weeklyOrders,
    required this.customersCount,
    required this.avgOrderAmount,
  });

  factory ServiceAreaOpportunityModel.fromJson(Map<String, dynamic> json) {
    return ServiceAreaOpportunityModel(
      location: json['location'] as Map<String, dynamic>,
      weeklyOrders: json['weekly_orders'] as int,
      customersCount: json['customers_count'] as int,
      avgOrderAmount: json['avg_order_amount'] as String,
    );
  }
}
