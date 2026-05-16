import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/errors/app_error_handler.dart';
import '../../data/datasources/seller_orders_remote_datasource.dart';
import '../../data/models/seller_order_model.dart';

final sellerOrdersProvider =
    NotifierProvider<SellerOrdersNotifier, SellerOrdersState>(
        SellerOrdersNotifier.new);

class SellerOrdersState {
  final List<SellerOrderModel> orders;
  final bool isLoading;
  final String? error;

  const SellerOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  List<SellerOrderModel> get activeOrders =>
      orders.where((o) => o.status != SellerOrderStatus.done).toList();

  int get activeCount => activeOrders.length;

  SellerOrdersState copyWith({
    List<SellerOrderModel>? orders,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SellerOrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SellerOrdersNotifier extends Notifier<SellerOrdersState> {
  @override
  SellerOrdersState build() {
    Future.microtask(_loadOrders);
    return const SellerOrdersState(isLoading: true);
  }

  SellerOrdersRemoteDatasource get _ds =>
      ref.read(sellerOrdersRemoteDatasourceProvider);

  Future<void> _loadOrders() async {
    try {
      final summaries = await _ds.getActiveOrders();
      state = state.copyWith(orders: summaries);

      // Enrich each order with full detail in parallel
      final details = await Future.wait(
        summaries
            .where((o) => o.id.isNotEmpty)
            .map((o) => _ds.getOrderDetail(o.id).catchError((_) => o)),
      );

      final detailMap = {for (final d in details) d.id: d};
      final enriched = summaries.map((o) => detailMap[o.id] ?? o).toList();

      state = state.copyWith(orders: enriched, isLoading: false);
    } on ApiException catch (e) {
      if (!AppErrorHandler.isUnauthorized(e)) {
        state = state.copyWith(
          isLoading: false,
          error: AppErrorHandler.getUserMessage(e),
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _loadOrders();
  }

  void setDeliveryTime(String orderId, int minutes) {
    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == orderId
              ? o.copyWith(deliveryTimeMinutes: minutes)
              : o)
          .toList(),
    );
  }

  Future<void> toggleItemChecked(String orderId, String itemId) async {
    final order = state.orders.where((o) => o.id == orderId).firstOrNull;
    if (order == null) return;
    final item = order.items.where((i) => i.id == itemId).firstOrNull;
    if (item == null) return;

    // Optimistic toggle
    state = state.copyWith(
      orders: state.orders.map((o) {
        if (o.id != orderId) return o;
        return o.copyWith(
          items: o.items
              .map((i) => i.id == itemId
                  ? i.copyWith(isChecked: !i.isChecked)
                  : i)
              .toList(),
        );
      }).toList(),
    );

    if (!item.isChecked) {
      // Only call API when checking (marking gotten), not unchecking
      try {
        await _ds.markItemGotten(orderId, itemId);
      } on ApiException catch (e) {
        if (!AppErrorHandler.isUnauthorized(e)) {
          // Rollback
          state = state.copyWith(
            orders: state.orders.map((o) {
              if (o.id != orderId) return o;
              return o.copyWith(
                items: o.items
                    .map((i) => i.id == itemId
                        ? i.copyWith(isChecked: false)
                        : i)
                    .toList(),
              );
            }).toList(),
          );
        }
      } catch (_) {
        // Non-fatal
      }
    }
  }

  Future<void> advanceStatus(String orderId) async {
    final order = state.orders.where((o) => o.id == orderId).firstOrNull;
    if (order == null) return;

    final nextStatus = switch (order.status) {
      SellerOrderStatus.accepted => SellerOrderStatus.shopping,
      SellerOrderStatus.shopping => SellerOrderStatus.delivering,
      SellerOrderStatus.delivering => SellerOrderStatus.done,
      SellerOrderStatus.done => SellerOrderStatus.done,
    };

    if (nextStatus == order.status) return;

    // Optimistic update
    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == orderId ? o.copyWith(status: nextStatus) : o)
          .toList(),
    );

    try {
      switch (order.status) {
        case SellerOrderStatus.accepted:
          await _ds.startShopping(orderId);
        case SellerOrderStatus.shopping:
          await _ds.markOnTheWay(orderId);
        case SellerOrderStatus.delivering:
          await _ds.markDelivered(orderId);
        case SellerOrderStatus.done:
          break;
      }
    } on ApiException catch (e) {
      if (!AppErrorHandler.isUnauthorized(e)) {
        // Rollback
        state = state.copyWith(
          orders: state.orders
              .map((o) =>
                  o.id == orderId ? o.copyWith(status: order.status) : o)
              .toList(),
          error: AppErrorHandler.getUserMessage(e),
        );
      }
    } catch (_) {
      // Rollback
      state = state.copyWith(
        orders: state.orders
            .map((o) => o.id == orderId ? o.copyWith(status: order.status) : o)
            .toList(),
      );
    }
  }

  SellerOrderModel? getOrder(String orderId) {
    return state.orders.where((o) => o.id == orderId).firstOrNull;
  }
}
