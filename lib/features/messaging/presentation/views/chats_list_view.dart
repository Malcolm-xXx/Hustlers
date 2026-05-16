import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/navigation/route_names.dart';
import '../../data/models/chat_model.dart';
import '../providers/messaging_provider.dart';
import '../widgets/chat_menu_sheet.dart';

class ChatsListView extends ConsumerWidget {
  const ChatsListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messagingProvider);
    final notifier = ref.read(messagingProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(Icons.arrow_back_ios_new,
                        size: 20.sp, color: AppColors.textDark),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Chats',
                    style: AppTextStyle.headingSm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => showChatsListMenu(context, notifier),
                    child: Icon(Icons.more_vert,
                        size: 22.sp, color: AppColors.textDark),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: GestureDetector(
                onTap: () =>
                    context.pushNamed(RouteNames.searchChat),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: AppColors.white100,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search,
                          size: 20.sp, color: AppColors.textGrey),
                      SizedBox(width: 10.w),
                      Text(
                        'Search by name, order, or message...',
                        style: AppTextStyle.bodySm.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 8.h),

            // Content
            Expanded(
              child: state.hasChats
                  ? _buildChatsList(context, state, notifier)
                  : _buildEmptyState(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsList(BuildContext context, MessagingState state,
      MessagingNotifier notifier) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      children: [
        if (state.activeChats.isNotEmpty) ...[
          SizedBox(height: 16.h),
          Text(
            'Active Chats',
            style: AppTextStyle.labelMd.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 8.h),
          ...state.activeChats.map((chat) =>
              _buildChatItem(context, chat)),
        ],

        SizedBox(height: 16.h),
        GestureDetector(
          onTap: () => notifier.toggleResolvedSection(),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resolved Chats',
                  style: AppTextStyle.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                    fontSize: 13.sp,
                  ),
                ),
                AnimatedRotation(
                  turns: state.isResolvedExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down,
                      size: 22.sp, color: AppColors.textDark),
                ),
              ],
            ),
          ),
        ),

        if (state.isResolvedExpanded && state.resolvedChats.isNotEmpty)
          ...state.resolvedChats
              .map((chat) => _buildChatItem(context, chat)),

        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildChatItem(BuildContext context, ChatModel chat) {
    return GestureDetector(
      onTap: () => context.pushNamed(
        RouteNames.chatConversation,
        extra: chat.id,
      ),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: 6.h),
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22.r,
              backgroundColor: AppColors.highlight,
              backgroundImage: chat.buyerAvatarUrl.isNotEmpty
                  ? NetworkImage(chat.buyerAvatarUrl)
                  : null,
              child: chat.buyerAvatarUrl.isEmpty
                  ? Icon(Icons.person,
                      size: 40.sp, color: AppColors.light)
                  : null,
            ),
            SizedBox(width: 12.w),

            // Name, order badge, message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          chat.buyerName,
                          style: AppTextStyle.labelMd.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // Order badge
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary100,
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Text(
                          'Order ${chat.orderNumber}',
                          style: AppTextStyle.bodySm.copyWith(
                            fontFamily: 'Poppins',
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.hash,
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      // Online indicator
                      chat.isResolved?Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: AppColors.grey500,
                          shape: BoxShape.circle,
                        ),
                      ): SizedBox.shrink(),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    chat.lastMessage,
                    style: AppTextStyle.bodySm.copyWith(
                      color: AppColors.textGrey,
                      fontSize: 12.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(width: 8.w),

            // Unread badge + time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (chat.unreadCount > 0)
                  Container(
                    width: 22.w,
                    height: 22.w,
                    decoration: const BoxDecoration(
                      color: AppColors.primary500,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${chat.unreadCount}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                if (chat.time.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    chat.time,
                    style: AppTextStyle.bodySm.copyWith(
                      color: AppColors.textGrey,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
                Icons.chat_bubble_outline_rounded,
                size: 64.sp,
                color: AppColors.grey500.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No Conversations Yet',
              style: AppTextStyle.headingSm.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.secondary500,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your messages with Buyers will appear here',
              style: AppTextStyle.bodyMd.copyWith(
                color: AppColors.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: 200.w,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary500,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Search for Lists',
                  style: AppTextStyle.bodyMd.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
