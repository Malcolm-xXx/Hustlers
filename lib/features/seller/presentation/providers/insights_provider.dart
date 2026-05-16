import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/insights_model.dart';

export '../../data/models/insights_model.dart' show InsightsPeriod, InsightsData;

final insightsProvider =
    NotifierProvider<InsightsNotifier, InsightsState>(InsightsNotifier.new);

class InsightsState {
  final InsightsPeriod period;
  final InsightsData data;
  final bool isLoading;
  final String? error;

  const InsightsState({
    this.period = InsightsPeriod.today,
    this.data = InsightsData.emptyData,
    this.isLoading = false,
    this.error,
  });

  bool get hasData => data.totalEarnings > 0;

  InsightsState copyWith({
    InsightsPeriod? period,
    InsightsData? data,
    bool? isLoading,
    String? error,
  }) {
    return InsightsState(
      period: period ?? this.period,
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class InsightsNotifier extends Notifier<InsightsState> {
  @override
  InsightsState build() {
    Future.microtask(() => _load(InsightsPeriod.today));
    return const InsightsState(isLoading: true);
  }

  Future<void> _load(InsightsPeriod period) async {
    state = state.copyWith(isLoading: true, error: null, period: period);
    await Future.delayed(const Duration(milliseconds: 350));
    final data = switch (period) {
      InsightsPeriod.today => InsightsData.todayData,
      InsightsPeriod.week => InsightsData.weekData,
      InsightsPeriod.month => InsightsData.monthData,
    };
    state = state.copyWith(isLoading: false, data: data);
  }

  void setPeriod(InsightsPeriod period) => _load(period);
}

// ── Service Area ─────────────────────────────────────────────────────────────

final serviceAreaProvider =
    NotifierProvider<ServiceAreaNotifier, ServiceAreaState>(
        ServiceAreaNotifier.new);

class ServiceAreaState {
  final List<ServiceAreaModel> activeAreas;
  final List<ServiceAreaModel> availableAreas;

  const ServiceAreaState({
    this.activeAreas = const [],
    this.availableAreas = const [],
  });

  int get selectedCount => availableAreas.where((a) => a.isSelected).length;

  ServiceAreaState copyWith({
    List<ServiceAreaModel>? activeAreas,
    List<ServiceAreaModel>? availableAreas,
  }) {
    return ServiceAreaState(
      activeAreas: activeAreas ?? this.activeAreas,
      availableAreas: availableAreas ?? this.availableAreas,
    );
  }
}

class ServiceAreaNotifier extends Notifier<ServiceAreaState> {
  @override
  ServiceAreaState build() => ServiceAreaState(
        activeAreas: ServiceAreaModel.mockActiveAreas,
        availableAreas: ServiceAreaModel.mockAvailableAreas,
      );

  void toggleAreaSelection(String areaId) {
    state = state.copyWith(
      availableAreas: state.availableAreas
          .map((a) => a.id == areaId ? a.copyWith(isSelected: !a.isSelected) : a)
          .toList(),
    );
  }

  void removeActiveArea(String areaId) {
    final area = state.activeAreas.where((a) => a.id == areaId).firstOrNull;
    if (area == null) return;
    state = state.copyWith(
      activeAreas: state.activeAreas.where((a) => a.id != areaId).toList(),
      availableAreas: [...state.availableAreas, area.copyWith(isActive: false)],
    );
  }

  void saveCoverageAreas() {
    final selected = state.availableAreas.where((a) => a.isSelected).toList();
    final remaining = state.availableAreas.where((a) => !a.isSelected).toList();
    state = state.copyWith(
      activeAreas: [
        ...state.activeAreas,
        ...selected.map((a) => a.copyWith(isActive: true, isSelected: false)),
      ],
      availableAreas: remaining,
    );
  }
}
