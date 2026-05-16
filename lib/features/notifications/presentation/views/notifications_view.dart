import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../data/models/notification_model.dart';
import '../providers/notifications_provider.dart';

class NotificationsView extends ConsumerStatefulWidget {
  const NotificationsView({super.key});

  @override
  ConsumerState<NotificationsView> createState() =>
      _NotificationsViewState();
}

class _NotificationsViewState extends ConsumerState<NotificationsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(Icons.arrow_back_ios_new,
                        size: 20.sp, color: AppColors.textDark),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Notifications',
                    style: AppTextStyle.headingSm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  // Mark all button
                  GestureDetector(
                    onTap: () => notifier.markAllAsRead(),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary500,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check,
                              size: 14.sp, color: AppColors.textDark),
                          SizedBox(width: 4.w),
                          Text(
                            'Mark all',
                            style: AppTextStyle.bodySm.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Custom tab bar
            _buildCustomTabBar(state),

            SizedBox(height: 4.h),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Hustles tab
                  _buildHustlesTab(state, notifier),
                  // Account tab
                  _buildAccountTab(state, notifier),
                  // Overdue tab
                  _buildOverdueTab(state, notifier),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTabBar(NotificationsState state) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.symmetric(vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          // Hustles tab
          Expanded(
            child: _buildTabItem(
              label: 'Hustles',
              index: 0,
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 18.h,
            color: AppColors.grey500.withOpacity(0.4),
          ),
          // Account tab
          Expanded(
            child: _buildTabItem(
              label: 'Account',
              index: 1,
              badgeCount: state.accountUnreadCount,
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 18.h,
            color: AppColors.grey500.withOpacity(0.4),
          ),
          // Overdue tab
          Expanded(
            child: _buildTabItem(
              label: 'Overdue',
              index: 2,
              badgeCount: state.overdueUnreadCount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required String label,
    required int index,
    int badgeCount = 0,
  }) {
    final isSelected = _tabController.index == index;

    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTextStyle.labelMd.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13.sp,
                color: isSelected ? AppColors.textDark : AppColors.textGrey,
              ),
            ),
            if (badgeCount > 0) ...[
              SizedBox(width: 5.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppColors.verifiedGreen,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── HUSTLES TAB ───

  Widget _buildHustlesTab(
      NotificationsState state, NotificationsNotifier notifier) {
    final items = state.hustlesNotifications;

    if (items.isEmpty) {
      return _buildEmptyState(
        'All Quiet for now',
        'All updates and important information will appear here',
      );
    }

    final grouped = state.groupedHustlesBySection;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      children: [
        ...grouped.entries.expand((entry) => [
              // Section header
              Padding(
                padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
                child: Row(
                  children: [
                    if (entry.key == 'From Hustles') ...[
                      Container(
                        width: 8.w,
                        height: 8.h,
                        decoration: const BoxDecoration(
                          color: AppColors.verifiedGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    Text(
                      entry.key,
                      style: AppTextStyle.labelMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.grey50),
              SizedBox(height: 8.h),
              // Notification cards
              ...entry.value.map(
                  (notification) => _buildNotificationCard(notification, notifier)),
            ]),
        SizedBox(height: 20.h),
        // Load More
        Center(
          child: GestureDetector(
            onTap: () {
              // TODO: Load more
            },
            child: Text(
              'Load More',
              style: AppTextStyle.labelMd.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  // ─── ACCOUNT TAB ───

  Widget _buildAccountTab(
      NotificationsState state, NotificationsNotifier notifier) {
    final items = state.accountNotifications;

    if (items.isEmpty) {
      return _buildEmptyState(
        'All Quiet for now',
        'All updates and important information will appear here',
      );
    }

    final grouped = state.groupByDate(items);

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      children: [
        ...grouped.entries.expand((entry) => [
              Padding(
                padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: AppTextStyle.labelMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Divider(height: 1, color: AppColors.grey50),
                  ],
                ),
              ),
              ...entry.value.map(
                  (notification) => _buildNotificationCard(notification, notifier)),
            ]),
        SizedBox(height: 20.h),
        // Swipe hint
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\u{1F447} ',
                style: TextStyle(fontSize: 14.sp),
              ),
              Text(
                'Swipe left to dismiss notifications',
                style: AppTextStyle.bodySm.copyWith(
                  color: AppColors.textGrey,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  // ─── OVERDUE TAB ───

  Widget _buildOverdueTab(
      NotificationsState state, NotificationsNotifier notifier) {
    final items = state.overdueNotifications;

    if (items.isEmpty) {
      return _buildEmptyState(
        'All Quiet for now',
        'All updates and important information will appear here',
      );
    }

    final grouped = state.groupByDate(items);

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      children: [
        ...grouped.entries.expand((entry) => [
              Padding(
                padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: AppTextStyle.labelMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Divider(height: 1, color: AppColors.grey50),
                  ],
                ),
              ),
              ...entry.value.map(
                  (notification) => _buildNotificationCard(notification, notifier)),
            ]),
        SizedBox(height: 20.h),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\u{1F447} ',
                style: TextStyle(fontSize: 14.sp),
              ),
              Text(
                'Swipe left to dismiss notifications',
                style: AppTextStyle.bodySm.copyWith(
                  color: AppColors.textGrey,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  // ─── EMPTY STATE ───

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140.w,
              height: 140.w,
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 64.sp,
                color: AppColors.grey500.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 28.h),
            Text(
              title,
              style: AppTextStyle.headingSm.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              subtitle,
              style: AppTextStyle.bodyMd.copyWith(
                color: AppColors.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── NOTIFICATION CARD ───

  Widget _buildNotificationCard(
      NotificationModel notification, NotificationsNotifier notifier) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => notifier.dismiss(notification.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: AppColors.logOutRed,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child:
            Icon(Icons.delete_outline, color: AppColors.white, size: 24.sp),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.white
              : AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.grey50),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: notification.iconBgColor,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    notification.iconData,
                    size: 20.sp,
                    color: notification.iconColor,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    notification.title,
                                    style: AppTextStyle.labelMd.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.sp,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!notification.isRead) ...[
                                  SizedBox(width: 6.w),
                                  Container(
                                    width: 7.w,
                                    height: 7.w,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary500,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          // Time
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time,
                                  size: 12.sp, color: AppColors.textGrey),
                              SizedBox(width: 3.w),
                              Text(
                                notification.timeAgo,
                                style: AppTextStyle.bodySm.copyWith(
                                  fontSize: 11.sp,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Earning badge (if present, show above description)
                      if (notification.earningText != null) ...[
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  size: 12.sp,
                                  color: AppColors.verifiedGreen),
                              SizedBox(width: 4.w),
                              Text(
                                notification.earningText!,
                                style: AppTextStyle.bodySm.copyWith(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.verifiedGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: 4.h),

                      // Description
                      Text(
                        notification.description,
                        style: AppTextStyle.bodySm.copyWith(
                          color: AppColors.textGrey,
                          height: 1.4,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Action buttons
            if (notification.needsAction && !notification.isRead) ...[
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.only(left: 52.w),
                child: _buildActionButtons(notification, notifier),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── ACTION BUTTONS ───

  Widget _buildActionButtons(
      NotificationModel notification, NotificationsNotifier notifier) {
    switch (notification.type) {
      case NotificationType.newHustleAvailable:
        return GestureDetector(
          onTap: () {},
          child: Text(
            'View Details',
            style: AppTextStyle.bodySm.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
              fontSize: 12.sp,
              decoration: TextDecoration.underline,
            ),
          ),
        );

      case NotificationType.newMessage:
        return Row(
          children: [
            _buildActionButton(
              label: 'Reply',
              color: AppColors.textDark,
              bgColor: Colors.transparent,
              borderColor: AppColors.grey50,
              onTap: () => notifier.markAsRead(notification.id),
            ),
          ],
        );

      case NotificationType.newOrder:
        return Row(
          children: [
            _buildActionButton(
              label: 'View Order',
              color: AppColors.white,
              bgColor: AppColors.secondary500,
              onTap: () => notifier.markAsRead(notification.id),
            ),
            SizedBox(width: 8.w),
            _buildActionButton(
              label: 'Decline',
              color: AppColors.logOutRed,
              bgColor: Colors.transparent,
              borderColor: AppColors.logOutRed,
              onTap: () => notifier.markAsRead(notification.id),
            ),
          ],
        );

      case NotificationType.priceAdjustment:
        return Row(
          children: [
            _buildActionButton(
              label: 'Approve',
              color: AppColors.verifiedGreen,
              bgColor: Colors.transparent,
              borderColor: AppColors.verifiedGreen,
              onTap: () => notifier.markAsRead(notification.id),
            ),
            SizedBox(width: 8.w),
            _buildActionButton(
              label: 'Cancel Item',
              color: AppColors.white,
              bgColor: AppColors.logOutRed,
              onTap: () => notifier.markAsRead(notification.id),
            ),
          ],
        );

      case NotificationType.orderCompleted:
        return GestureDetector(
          onTap: () {},
          child: Text(
            'Send a Reminder',
            style: AppTextStyle.bodySm.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
              fontSize: 12.sp,
              decoration: TextDecoration.underline,
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required Color bgColor,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20.r),
          border:
              borderColor != null ? Border.all(color: borderColor) : null,
        ),
        child: Text(
          label,
          style: AppTextStyle.bodySm.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }
}
