import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/route_names.dart';

final hustleListProvider =
    NotifierProvider<HustleListNotifier, HustleListState>(
        HustleListNotifier.new);

class HustleItem {
  final String id;
  final String name;
  final double? price;
  final String? note;

  const HustleItem({
    required this.id,
    required this.name,
    this.price,
    this.note,
  });

  HustleItem copyWith({
    String? name,
    double? price,
    String? note,
    bool clearNote = false,
  }) {
    return HustleItem(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      note: clearNote ? null : (note ?? this.note),
    );
  }
}

class FavouriteHustler {
  final String id;
  final String name;

  const FavouriteHustler({required this.id, required this.name});
}

class HustleListState {
  final List<HustleItem> items;
  final double? deliveryFee;
  final String? selectedLocation;
  final String? deliveryTime;
  final bool directRequestEnabled;
  final String? selectedHustlerId;
  final String? selectedHustlerName;
  final bool isLoading;
  final String? error;

  const HustleListState({
    this.items = const [],
    this.deliveryFee,
    this.selectedLocation,
    this.deliveryTime,
    this.directRequestEnabled = false,
    this.selectedHustlerId,
    this.selectedHustlerName,
    this.isLoading = false,
    this.error,
  });

  bool get canCreateList =>
      items.isNotEmpty && deliveryTime != null;

  bool get canPostList =>
      canCreateList &&
      (!directRequestEnabled || selectedHustlerId != null);

  HustleListState copyWith({
    List<HustleItem>? items,
    double? deliveryFee,
    bool clearDeliveryFee = false,
    String? selectedLocation,
    bool clearLocation = false,
    String? deliveryTime,
    bool clearDeliveryTime = false,
    bool? directRequestEnabled,
    String? selectedHustlerId,
    String? selectedHustlerName,
    bool clearHustler = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return HustleListState(
      items: items ?? this.items,
      deliveryFee:
          clearDeliveryFee ? null : (deliveryFee ?? this.deliveryFee),
      selectedLocation:
          clearLocation ? null : (selectedLocation ?? this.selectedLocation),
      deliveryTime:
          clearDeliveryTime ? null : (deliveryTime ?? this.deliveryTime),
      directRequestEnabled:
          directRequestEnabled ?? this.directRequestEnabled,
      selectedHustlerId: clearHustler
          ? null
          : (selectedHustlerId ?? this.selectedHustlerId),
      selectedHustlerName: clearHustler
          ? null
          : (selectedHustlerName ?? this.selectedHustlerName),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class HustleListNotifier extends Notifier<HustleListState> {
  @override
  HustleListState build() => const HustleListState();

  void addItem(HustleItem item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  void updateItem(String id, HustleItem updatedItem) {
    state = state.copyWith(
      items: state.items
          .map((item) => item.id == id ? updatedItem : item)
          .toList(),
    );
  }

  void removeItem(String id) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
    );
  }

  void setDeliveryFee(double fee) {
    state = state.copyWith(deliveryFee: fee);
  }

  void setLocation(String location) {
    state = state.copyWith(selectedLocation: location);
  }

  void setDeliveryTime(String time) {
    state = state.copyWith(deliveryTime: time);
  }

  void toggleDirectRequest() {
    final enabled = !state.directRequestEnabled;
    state = state.copyWith(
      directRequestEnabled: enabled,
      clearHustler: !enabled,
    );
  }

  void selectHustler(String id, String name) {
    state = state.copyWith(
      selectedHustlerId: id,
      selectedHustlerName: name,
    );
  }

  void reset() {
    state = const HustleListState();
  }

  // Mock favourites
  List<FavouriteHustler> get favouriteHustlers => const [
        FavouriteHustler(id: '1', name: 'Mama Ngozi'),
        FavouriteHustler(id: '2', name: 'Jude Simon'),
        FavouriteHustler(id: '3', name: 'Sisi Philips'),
        FavouriteHustler(id: '4', name: 'Sisi Philips'),
        FavouriteHustler(id: '5', name: 'The Drink Plug'),
        FavouriteHustler(id: '6', name: 'Ifeanyi Bulk Store'),
      ];

  void navigateToSuccess(BuildContext context) {
    if (context.mounted) {
      context.pushNamed(RouteNames.hustleListSuccess);
    }
  }

  void navigateToHome(BuildContext context) {
    if (context.mounted) {
      reset();
      context.goNamed(RouteNames.home);
    }
  }
}
