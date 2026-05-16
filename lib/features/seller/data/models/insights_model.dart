enum InsightsPeriod { today, week, month }

class InsightsData {
  final double totalEarnings;
  final String earningsChangePct;
  final int totalOrders;
  final String ordersChangePct;
  final int totalHustles;
  final String hustlesChangePct;
  final int totalViews;
  final String avgDeliveryTime;
  final String avgRating;
  final String successRate;
  final List<ChartPoint> chartPoints;
  final List<String> chartYLabels;
  final double chartYMax;
  final List<TopListing> topListings;
  final List<HotZone> hotZones;

  const InsightsData({
    required this.totalEarnings,
    required this.earningsChangePct,
    required this.totalOrders,
    required this.ordersChangePct,
    required this.totalHustles,
    required this.hustlesChangePct,
    required this.totalViews,
    required this.avgDeliveryTime,
    required this.avgRating,
    required this.successRate,
    required this.chartPoints,
    required this.chartYLabels,
    required this.chartYMax,
    required this.topListings,
    required this.hotZones,
  });

  bool get isEmpty => totalEarnings == 0;

  static const InsightsData todayData = InsightsData(
    totalEarnings: 12800,
    earningsChangePct: '+32%',
    totalOrders: 23,
    ordersChangePct: '+19%',
    totalHustles: 23,
    hustlesChangePct: '+19%',
    totalViews: 124,
    avgDeliveryTime: '12m',
    avgRating: '4.9',
    successRate: '98%',
    chartYMax: 6000,
    chartYLabels: ['N0k', 'N2k', 'N3k', 'N5k', 'N6k'],
    chartPoints: [
      ChartPoint(label: '9AM', amount: 2000),
      ChartPoint(label: '11AM', amount: 3200),
      ChartPoint(label: '1PM', amount: 4600),
      ChartPoint(label: '3PM', amount: 3800),
      ChartPoint(label: '5PM', amount: 5400),
      ChartPoint(label: '7PM', amount: 4100),
      ChartPoint(label: '9PM', amount: 3500),
    ],
    topListings: [
      TopListing(name: 'Yellow Garri', formattedPrice: '₦45,600', views: 245, progress: 0.95),
      TopListing(name: 'Foreign Rice', formattedPrice: '₦34,200', views: 189, progress: 0.78),
      TopListing(name: 'White Garri', formattedPrice: '₦28,800', views: 156, progress: 0.64),
      TopListing(name: 'Brown Beans', formattedPrice: '₦21,900', views: 134, progress: 0.55),
    ],
    hotZones: [
      HotZone(name: 'Hall 4 (Main Gate)', ordersCount: 48, percentage: 32),
      HotZone(name: 'Faculty of Arts', ordersCount: 36, percentage: 24),
      HotZone(name: 'Engineering Block', ordersCount: 27, percentage: 18),
      HotZone(name: 'Medical Sciences', ordersCount: 22, percentage: 15),
      HotZone(name: 'SUB Cafeteria', ordersCount: 16, percentage: 11),
    ],
  );

  static const InsightsData weekData = InsightsData(
    totalEarnings: 84200,
    earningsChangePct: '+14%',
    totalOrders: 156,
    ordersChangePct: '+12%',
    totalHustles: 98,
    hustlesChangePct: '+8%',
    totalViews: 820,
    avgDeliveryTime: '11m',
    avgRating: '4.9',
    successRate: '98%',
    chartYMax: 15000,
    chartYLabels: ['N0k', 'N5k', 'N8k', 'N12k', 'N15k'],
    chartPoints: [
      ChartPoint(label: 'Mon', amount: 8000),
      ChartPoint(label: 'Tue', amount: 12000),
      ChartPoint(label: 'Wed', amount: 11000),
      ChartPoint(label: 'Thu', amount: 13500),
      ChartPoint(label: 'Fri', amount: 10500),
      ChartPoint(label: 'Sat', amount: 9000),
      ChartPoint(label: 'Sun', amount: 7000),
    ],
    topListings: [
      TopListing(name: 'Yellow Garri', formattedPrice: '₦45,600', views: 245, progress: 0.95),
      TopListing(name: 'Foreign Rice', formattedPrice: '₦34,200', views: 189, progress: 0.78),
      TopListing(name: 'White Garri', formattedPrice: '₦28,800', views: 156, progress: 0.64),
      TopListing(name: 'Brown Beans', formattedPrice: '₦21,900', views: 134, progress: 0.55),
    ],
    hotZones: [
      HotZone(name: 'Hall 4 (Main Gate)', ordersCount: 48, percentage: 32),
      HotZone(name: 'Faculty of Arts', ordersCount: 36, percentage: 24),
      HotZone(name: 'Engineering Block', ordersCount: 27, percentage: 18),
      HotZone(name: 'Medical Sciences', ordersCount: 22, percentage: 15),
      HotZone(name: 'SUB Cafeteria', ordersCount: 16, percentage: 11),
    ],
  );

  static const InsightsData monthData = InsightsData(
    totalEarnings: 218600,
    earningsChangePct: '+24%',
    totalOrders: 587,
    ordersChangePct: '+19%',
    totalHustles: 270,
    hustlesChangePct: '+19%',
    totalViews: 298,
    avgDeliveryTime: '12m',
    avgRating: '4.9',
    successRate: '98%',
    chartYMax: 30000,
    chartYLabels: ['N0k', 'N8k', 'N15k', 'N23k', 'N30k'],
    chartPoints: [
      ChartPoint(label: 'Week 1', amount: 14000),
      ChartPoint(label: 'Week 2', amount: 22000),
      ChartPoint(label: 'Week 3', amount: 19000),
      ChartPoint(label: 'Week 4', amount: 28000),
    ],
    topListings: [
      TopListing(name: 'Yellow Garri', formattedPrice: '₦45,600', views: 245, progress: 0.95),
      TopListing(name: 'Foreign Rice', formattedPrice: '₦34,200', views: 189, progress: 0.78),
      TopListing(name: 'White Garri', formattedPrice: '₦28,800', views: 156, progress: 0.64),
      TopListing(name: 'Brown Beans', formattedPrice: '₦21,900', views: 134, progress: 0.55),
    ],
    hotZones: [
      HotZone(name: 'Hall 4 (Main Gate)', ordersCount: 48, percentage: 32),
      HotZone(name: 'Faculty of Arts', ordersCount: 36, percentage: 24),
      HotZone(name: 'Engineering Block', ordersCount: 27, percentage: 18),
      HotZone(name: 'Medical Sciences', ordersCount: 22, percentage: 15),
      HotZone(name: 'SUB Cafeteria', ordersCount: 16, percentage: 11),
    ],
  );

  static const InsightsData emptyData = InsightsData(
    totalEarnings: 0,
    earningsChangePct: '',
    totalOrders: 0,
    ordersChangePct: '',
    totalHustles: 0,
    hustlesChangePct: '',
    totalViews: 0,
    avgDeliveryTime: '0m',
    avgRating: '0.0',
    successRate: '0%',
    chartPoints: [],
    chartYLabels: [],
    chartYMax: 0,
    topListings: [],
    hotZones: [],
  );
}

class ChartPoint {
  final String label;
  final double amount;
  const ChartPoint({required this.label, required this.amount});
}

class TopListing {
  final String name;
  final String formattedPrice;
  final int views;
  final double progress;
  const TopListing({
    required this.name,
    required this.formattedPrice,
    required this.views,
    required this.progress,
  });
}

class HotZone {
  final String name;
  final int ordersCount;
  final int percentage;
  const HotZone({
    required this.name,
    required this.ordersCount,
    required this.percentage,
  });
}

// ── kept for ServiceAreaProvider ─────────────────────────────────────────────

class ServiceAreaModel {
  final String id;
  final String name;
  final double? avgEarning;
  final double demand;
  final bool isActive;
  final bool isSelected;

  const ServiceAreaModel({
    required this.id,
    required this.name,
    this.avgEarning,
    required this.demand,
    this.isActive = false,
    this.isSelected = false,
  });

  ServiceAreaModel copyWith({bool? isActive, bool? isSelected}) {
    return ServiceAreaModel(
      id: id,
      name: name,
      avgEarning: avgEarning,
      demand: demand,
      isActive: isActive ?? this.isActive,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  static final List<ServiceAreaModel> mockActiveAreas = [
    const ServiceAreaModel(id: 'a1', name: 'Medical Sciences', demand: 0.70, isActive: true),
    const ServiceAreaModel(id: 'a2', name: 'SUB Cafeteria', demand: 0.65, isActive: true),
  ];

  static final List<ServiceAreaModel> mockAvailableAreas = [
    const ServiceAreaModel(id: 'b1', name: 'New Site Area', avgEarning: 1850, demand: 0.85),
    const ServiceAreaModel(id: 'b2', name: 'Faculty of Science', avgEarning: 1950, demand: 0.75),
    const ServiceAreaModel(id: 'b3', name: 'Jaja Hall', avgEarning: 1750, demand: 0.68),
    const ServiceAreaModel(id: 'b4', name: 'Moremi Hall', avgEarning: 1900, demand: 0.60),
    const ServiceAreaModel(id: 'b5', name: 'Post Graduate Hall', avgEarning: 2100, demand: 0.55),
    const ServiceAreaModel(id: 'b6', name: 'Law Faculty', avgEarning: 2200, demand: 0.50),
    const ServiceAreaModel(id: 'b7', name: 'Mozambique Hall', avgEarning: 1800, demand: 0.45),
    const ServiceAreaModel(id: 'b8', name: 'Sports Complex', avgEarning: 1600, demand: 0.40),
  ];
}
