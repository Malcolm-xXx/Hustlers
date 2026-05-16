import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../data/models/chat_model.dart';
import '../providers/messaging_provider.dart';

// ─── CHATS LIST MENU ───

void showChatsListMenu(
    BuildContext context, MessagingNotifier notifier) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            _buildMenuItem(
              label: 'Mark all as read',
              onTap: () {
                notifier.markAllAsRead();
                Navigator.pop(context);
              },
            ),
            _buildMenuItem(
              label: 'Priority View',
              onTap: () => Navigator.pop(context),
            ),
            _buildMenuItem(
              label: 'Clear Resolved History',
              onTap: () {
                notifier.clearResolvedHistory();
                Navigator.pop(context);
              },
            ),
            _buildMenuItem(
              label: 'Seller Support',
              onTap: () => Navigator.pop(context),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    ),
  );
}

// ─── CONVERSATION MENU ───

void showConversationMenu(
  BuildContext context,
  MessagingNotifier notifier,
  ChatModel chat,
) {
  final isResolved = chat.isResolved;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            _buildMenuItem(
              label: 'View Buyer Profile',
              onTap: () => Navigator.pop(context),
            ),
            _buildMenuItem(
              label: 'View Order Details',
              onTap: () => Navigator.pop(context),
            ),
            if (!isResolved) ...[
              _buildMenuItem(
                label: 'Share my Location',
                onTap: () => Navigator.pop(context),
              ),
              _buildMenuItem(
                label: 'Mute Notifications',
                onTap: () => Navigator.pop(context),
              ),
              _buildMenuItem(
                label: 'Mark as Resolved',
                onTap: () {
                  notifier.markAsResolved(chat.id);
                  Navigator.pop(context);
                },
              ),
            ],
            if (isResolved)
              _buildMenuItem(
                label: 'Archive',
                onTap: () => Navigator.pop(context),
              ),
            _buildMenuItem(
              label: 'Report Buyer',
              color: AppColors.logOutRed,
              onTap: () => Navigator.pop(context),
            ),
            _buildMenuItem(
              label: 'Block Buyer',
              color: AppColors.logOutRed,
              onTap: () => Navigator.pop(context),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    ),
  );
}

Widget _buildMenuItem({
  required String label,
  Color? color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: AppTextStyle.bodyMd.copyWith(
            fontWeight: FontWeight.w500,
            color: color ?? AppColors.textDark,
            fontSize: 14.sp,
          ),
        ),
      ),
    ),
  );
}
