import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/errors/app_error_handler.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../../core/services/dio_provider.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../data/datasources/seller_remote_datasource.dart';
import '../../data/models/store_item_model.dart';
import '../../domain/repositories/i_seller_repository.dart';
import '../../data/repositories/seller_repository_impl.dart';

final sellerRemoteDatasourceProvider = Provider<SellerRemoteDatasource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return SellerRemoteDatasource(dioClient);
});

final sellerRepositoryProvider = Provider<ISellerRepository>((ref) {
  final datasource = ref.watch(sellerRemoteDatasourceProvider);
  return SellerRepositoryImpl(datasource);
});

final sellerProvider =
    NotifierProvider<SellerNotifier, SellerState>(SellerNotifier.new);

class SellerState {
  final bool isAvailable;
  final double walletBalance;
  final double walletGain;
  final List<StoreItemModel> storeItems;
  final List<StoreItemModel> drafts;
  final String storeName;
  final String selectedFilter;
  final bool isLoading;
  final String? error;

  const SellerState({
    this.isAvailable = true,
    this.walletBalance = 50500,
    this.walletGain = 30500,
    this.storeItems = const [],
    this.drafts = const [],
    this.storeName = "Aisha's Kitchen",
    this.selectedFilter = 'All',
    this.isLoading = false,
    this.error,
  });

  int get activeItemCount => storeItems.where((i) => i.inStock && !i.isDraft).length;
  int get onSaleCount => storeItems.where((i) => i.isOnSale).length;

  List<StoreItemModel> get filteredItems {
    if (selectedFilter == 'All') return storeItems;
    return storeItems.where((i) => i.category == selectedFilter).toList();
  }

  SellerState copyWith({
    bool? isAvailable,
    double? walletBalance,
    double? walletGain,
    List<StoreItemModel>? storeItems,
    List<StoreItemModel>? drafts,
    String? storeName,
    String? selectedFilter,
    bool? isLoading,
    String? error,
  }) {
    return SellerState(
      isAvailable: isAvailable ?? this.isAvailable,
      walletBalance: walletBalance ?? this.walletBalance,
      walletGain: walletGain ?? this.walletGain,
      storeItems: storeItems ?? this.storeItems,
      drafts: drafts ?? this.drafts,
      storeName: storeName ?? this.storeName,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SellerNotifier extends Notifier<SellerState> {
  @override
  SellerState build() {
    // Trigger initial fetch
    Future.microtask(() => fetchSellerProducts());
    
    return const SellerState(
      storeItems: [], // Start with empty, will be filled by fetch
      drafts: [],
    );
  }

  Future<void> fetchSellerProducts() async {
    state = state.copyWith(isLoading: true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.getMe();
      final sellerRepo = ref.read(sellerRepositoryProvider);
      final products = await sellerRepo.getSellerProducts(user.id);
      
      state = state.copyWith(
        isLoading: false,
        storeItems: products.map((e) => StoreItemModel.fromEntity(e)).toList(),
      );
    } on ApiException catch (e) {
      if (AppErrorHandler.isUnauthorized(e)) return;
      state = state.copyWith(isLoading: false, error: AppErrorHandler.getUserMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Something went wrong. Please try again.');
    }
  }

  void toggleAvailability() {
    state = state.copyWith(isAvailable: !state.isAvailable);
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void toggleItemStock(String itemId) {
    state = state.copyWith(
      storeItems: state.storeItems
          .map((i) => i.id == itemId ? i.copyWith(inStock: !i.inStock) : i)
          .toList(),
    );
  }

  void addItem(StoreItemModel item) {
    state = state.copyWith(storeItems: [...state.storeItems, item]);
  }

  void updateItem(String id, StoreItemModel updatedItem) {
    state = state.copyWith(
      storeItems: state.storeItems
          .map((i) => i.id == id ? updatedItem : i)
          .toList(),
    );
  }

  void removeItem(String id) {
    state = state.copyWith(
      storeItems: state.storeItems.where((i) => i.id != id).toList(),
    );
  }

  void removeDraft(String id) {
    state = state.copyWith(
      drafts: state.drafts.where((i) => i.id != id).toList(),
    );
  }

  void navigateToAddItem(BuildContext context) {
    if (context.mounted) {
      context.pushNamed(RouteNames.addStoreItem);
    }
  }

  void navigateToEditItem(BuildContext context, StoreItemModel item) {
    if (context.mounted) {
      context.pushNamed(RouteNames.editStoreItem, extra: item);
    }
  }
}
