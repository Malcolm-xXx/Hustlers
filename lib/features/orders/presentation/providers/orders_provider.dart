import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/errors/app_error_handler.dart';
import '../../../../core/navigation/route_names.dart';
import '../../data/datasources/orders_remote_datasource.dart';
import '../../data/models/order_model.dart';

final ordersProvider =
    NotifierProvider<OrdersNotifier, OrdersState>(OrdersNotifier.new);

class OrdersState {
  final List<OrderModel> orders;
  final bool isLoading;
  final String? error;

  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  OrdersState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OrdersNotifier extends Notifier<OrdersState> {
  @override
  OrdersState build() {
    Future.microtask(_loadOrders);
    return const OrdersState(isLoading: true);
  }

  OrdersRemoteDatasource get _ds => ref.read(ordersRemoteDatasourceProvider);

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
      final enriched = summaries
          .map((o) => detailMap[o.id] ?? o)
          .toList();

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

  Future<void> cancelItem(String orderId, String itemId) async {
    try {
      await _ds.cancelOrderItem(orderId, itemId);
      // Optimistically mark as cancelled in state
      state = state.copyWith(
        orders: state.orders.map((order) {
          if (order.id == orderId) {
            return order.copyWith(
              items: order.items
                  .map((item) =>
                      item.id == itemId ? item.copyWith(isCancelled: true) : item)
                  .toList(),
            );
          }
          return order;
        }).toList(),
      );
    } on ApiException catch (e) {
      if (!AppErrorHandler.isUnauthorized(e)) {
        state = state.copyWith(error: AppErrorHandler.getUserMessage(e));
      }
    } catch (_) {
      // Silently ignore
    }
  }

  void markAsDelivered(String orderId) {
    state = state.copyWith(
      orders: state.orders.map((order) {
        if (order.id == orderId) {
          return order.copyWith(status: OrderStatus.done);
        }
        return order;
      }).toList(),
    );
  }

  void navigateToLiveStatus(BuildContext context, OrderModel order) {
    if (context.mounted) {
      context.pushNamed(RouteNames.liveStatus, extra: order);
    }
  }

  void navigateToRateExperience(BuildContext context, OrderModel order) {
    if (context.mounted) {
      context.pushNamed(RouteNames.rateExperience, extra: order);
    }
  }
}

// ── Rate experience provider ──────────────────────────────────────────────────

final rateExperienceProvider =
    NotifierProvider<RateExperienceNotifier, RateExperienceState>(
        RateExperienceNotifier.new);

class RateExperienceState {
  final int starRating;
  final Set<String> selectedTags;
  final String comment;
  final bool isSubmitting;
  final bool isSuccess;
  final String? error;

  const RateExperienceState({
    this.starRating = 0,
    this.selectedTags = const {},
    this.comment = '',
    this.isSubmitting = false,
    this.isSuccess = false,
    this.error,
  });

  bool get canSubmit => starRating > 0;

  RateExperienceState copyWith({
    int? starRating,
    Set<String>? selectedTags,
    String? comment,
    bool? isSubmitting,
    bool? isSuccess,
    String? error,
    bool clearError = false,
  }) {
    return RateExperienceState(
      starRating: starRating ?? this.starRating,
      selectedTags: selectedTags ?? this.selectedTags,
      comment: comment ?? this.comment,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RateExperienceNotifier extends Notifier<RateExperienceState> {
  @override
  RateExperienceState build() => const RateExperienceState();

  void setStarRating(int rating) =>
      state = state.copyWith(starRating: rating);

  void toggleTag(String tag) {
    final tags = Set<String>.from(state.selectedTags);
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
    state = state.copyWith(selectedTags: tags);
  }

  void setComment(String comment) => state = state.copyWith(comment: comment);

  Future<void> submitRating(String orderId) async {
    if (!state.canSubmit) return;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await ref.read(ordersRemoteDatasourceProvider).rateOrder(
            orderId,
            rating: state.starRating,
            feedbackTags: state.selectedTags.toList(),
            review: state.comment.isNotEmpty ? state.comment : null,
          );
      state = state.copyWith(isSubmitting: false, isSuccess: true);
    } on ApiException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: AppErrorHandler.getUserMessage(e),
      );
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  void reset() => state = const RateExperienceState();
}
