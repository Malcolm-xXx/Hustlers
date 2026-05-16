import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/errors/app_error_handler.dart';
import '../../data/datasources/notifications_remote_datasource.dart';
import '../../data/models/notification_model.dart';

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(
        NotificationsNotifier.new);

class NotificationsState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  List<NotificationModel> get hustlesNotifications =>
      notifications.where((n) => n.tab == NotificationTab.hustles).toList();

  List<NotificationModel> get accountNotifications =>
      notifications.where((n) => n.tab == NotificationTab.account).toList();

  List<NotificationModel> get overdueNotifications =>
      notifications.where((n) => n.tab == NotificationTab.overdue).toList();

  int get accountUnreadCount =>
      accountNotifications.where((n) => !n.isRead).length;

  int get overdueUnreadCount =>
      overdueNotifications.where((n) => !n.isRead || n.needsAction).length;

  Map<String, List<NotificationModel>> get groupedHustlesBySection {
    final map = <String, List<NotificationModel>>{};
    for (final n in hustlesNotifications) {
      final key = n.subSection ?? 'Other';
      map.putIfAbsent(key, () => []).add(n);
    }
    return map;
  }

  Map<String, List<NotificationModel>> groupByDate(
      List<NotificationModel> items) {
    final map = <String, List<NotificationModel>>{};
    final now = DateTime.now();
    for (final n in items) {
      final diff = now.difference(n.createdAt);
      String key;
      if (diff.inDays == 0) {
        key = 'Today';
      } else if (diff.inDays == 1) {
        key = 'Yesterday';
      } else {
        key = '${diff.inDays} days ago';
      }
      map.putIfAbsent(key, () => []).add(n);
    }
    return map;
  }

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  @override
  NotificationsState build() {
    Future.microtask(_loadNotifications);
    return const NotificationsState(isLoading: true);
  }

  NotificationsRemoteDatasource get _ds =>
      ref.read(notificationsRemoteDatasourceProvider);

  Future<void> _loadNotifications() async {
    try {
      final apiModels = await _ds.getNotifications();
      final uiModels = apiModels.map((m) => m.toUiModel()).toList();
      state = state.copyWith(notifications: uiModels, isLoading: false);
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
    await _loadNotifications();
  }

  Future<void> markAllAsRead() async {
    // Optimistic update
    state = state.copyWith(
      notifications:
          state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
    );
    try {
      await _ds.markAllRead();
    } on ApiException catch (_) {
      // Non-fatal — optimistic state stays
    } catch (_) {
      // Non-fatal
    }
  }

  Future<void> markAsRead(String id) async {
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList(),
    );
    try {
      await _ds.markRead(id);
    } on ApiException catch (_) {
      // Non-fatal
    } catch (_) {
      // Non-fatal
    }
  }

  void dismiss(String id) {
    state = state.copyWith(
      notifications:
          state.notifications.where((n) => n.id != id).toList(),
    );
  }
}
