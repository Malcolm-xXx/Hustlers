import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/errors/app_error_handler.dart';
import '../../data/datasources/stash_remote_datasource.dart';
import '../../data/models/stash_models.dart';

final stashProvider =
    NotifierProvider<StashNotifier, StashState>(StashNotifier.new);

class StashState {
  final List<StashItem> items;
  final String deliveryAddress;
  final String specialInstructions;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double grandTotal;
  final bool isLoading;
  final String? error;

  const StashState({
    this.items = const [],
    this.deliveryAddress = '',
    this.specialInstructions = '',
    this.subtotal = 0,
    this.deliveryFee = 0,
    this.serviceFee = 0,
    this.grandTotal = 0,
    this.isLoading = false,
    this.error,
  });

  int get totalItemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  StashState copyWith({
    List<StashItem>? items,
    String? deliveryAddress,
    String? specialInstructions,
    double? subtotal,
    double? deliveryFee,
    double? serviceFee,
    double? grandTotal,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return StashState(
      items: items ?? this.items,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      serviceFee: serviceFee ?? this.serviceFee,
      grandTotal: grandTotal ?? this.grandTotal,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class StashNotifier extends Notifier<StashState> {
  @override
  StashState build() {
    Future.microtask(_loadStash);
    return const StashState(isLoading: true);
  }

  StashRemoteDatasource get _ds => ref.read(stashRemoteDatasourceProvider);

  Future<void> _loadStash() async {
    try {
      final model = await _ds.getStash();
      state = _fromApiModel(model);
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

  StashState _fromApiModel(StashApiModel model) => StashState(
        items: model.items.map((e) => e.toUiModel()).toList(),
        deliveryAddress: model.deliveryAddress ?? '',
        specialInstructions: model.specialInstructions ?? '',
        subtotal: model.subtotal.toDouble(),
        deliveryFee: model.deliveryFee.toDouble(),
        serviceFee: model.serviceFee.toDouble(),
        grandTotal: model.total.toDouble(),
        isLoading: false,
      );

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _loadStash();
  }

  Future<void> incrementQuantity(String itemId) async {
    final item = state.items.where((i) => i.id == itemId).firstOrNull;
    if (item == null) return;
    final optimistic = state.copyWith(
      items: state.items
          .map((i) => i.id == itemId
              ? i.copyWith(quantity: i.quantity + 1)
              : i)
          .toList(),
    );
    state = optimistic;
    try {
      final updated = await _ds.updateItem(itemId, item.quantity + 1);
      state = _fromApiModel(updated);
    } on ApiException catch (e) {
      if (!AppErrorHandler.isUnauthorized(e)) {
        state = state.copyWith(error: AppErrorHandler.getUserMessage(e));
        _rollback(optimistic);
      }
    } catch (_) {
      _rollback(optimistic);
    }
  }

  Future<void> decrementQuantity(String itemId) async {
    final item = state.items.where((i) => i.id == itemId).firstOrNull;
    if (item == null) return;
    final beforeState = state;
    if (item.quantity <= 1) {
      await removeItem(itemId);
      return;
    }
    final optimistic = state.copyWith(
      items: state.items
          .map((i) => i.id == itemId
              ? i.copyWith(quantity: i.quantity - 1)
              : i)
          .toList(),
    );
    state = optimistic;
    try {
      final updated = await _ds.updateItem(itemId, item.quantity - 1);
      state = _fromApiModel(updated);
    } on ApiException catch (e) {
      if (!AppErrorHandler.isUnauthorized(e)) {
        state = state.copyWith(error: AppErrorHandler.getUserMessage(e));
        state = beforeState;
      }
    } catch (_) {
      state = beforeState;
    }
  }

  Future<void> removeItem(String itemId) async {
    final beforeState = state;
    state = state.copyWith(
      items: state.items.where((i) => i.id != itemId).toList(),
    );
    try {
      final updated = await _ds.deleteItem(itemId);
      state = _fromApiModel(updated);
    } on ApiException catch (e) {
      if (!AppErrorHandler.isUnauthorized(e)) {
        state = beforeState.copyWith(error: AppErrorHandler.getUserMessage(e));
      } else {
        state = beforeState;
      }
    } catch (_) {
      state = beforeState;
    }
  }

  Future<void> clearStash() async {
    final beforeState = state;
    state = const StashState();
    try {
      await _ds.clearStash();
    } on ApiException catch (e) {
      if (!AppErrorHandler.isUnauthorized(e)) {
        state = beforeState.copyWith(error: AppErrorHandler.getUserMessage(e));
      } else {
        state = beforeState;
      }
    } catch (_) {
      state = beforeState;
    }
  }

  Future<void> updateDeliveryAddress(String address) async {
    state = state.copyWith(deliveryAddress: address);
  }

  Future<void> updateSpecialInstructions(String instructions) async {
    state = state.copyWith(specialInstructions: instructions);
    try {
      final updated = await _ds.updateStash(specialInstructions: instructions);
      state = _fromApiModel(updated);
    } on ApiException catch (_) {
      // Non-fatal
    } catch (_) {
      // Non-fatal
    }
  }

  void _rollback(StashState previous) => state = previous;
}
