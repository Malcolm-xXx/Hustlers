import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../data/models/chat_model.dart';
import '../providers/messaging_provider.dart';
import '../widgets/chat_menu_sheet.dart';

class ChatConversationView extends ConsumerStatefulWidget {
  final String chatId;

  const ChatConversationView({super.key, required this.chatId});

  @override
  ConsumerState<ChatConversationView> createState() =>
      _ChatConversationViewState();
}

class _ChatConversationViewState
    extends ConsumerState<ChatConversationView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    ref.read(messagingProvider.notifier).sendMessage(widget.chatId, text);
    _controller.clear();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(messagingProvider);
    final notifier = ref.read(messagingProvider.notifier);
    final chat = notifier.getChat(widget.chatId);
    final messages = notifier.getMessages(widget.chatId);

    if (chat == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('Chat not found', style: AppTextStyle.bodyMd),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, chat, notifier),

            // Resolved banner
            if (chat.isResolved)
              _buildResolvedBanner(),

            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(
                    horizontal: 20.w, vertical: 12.h),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final showSenderName = !message.isMe &&
                      message.senderName != null &&
                      (index == 0 ||
                          messages[index - 1].isMe ||
                          messages[index - 1].senderName !=
                              message.senderName);
                  return _buildMessageBubble(
                      message, showSenderName);
                },
              ),
            ),

            // Input bar
            _buildInputBar(chat),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ChatModel chat,
      MessagingNotifier notifier) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(Icons.arrow_back_ios_new,
                size: 20.sp, color: AppColors.textDark),
          ),
          SizedBox(width: 10.w),

          // Avatar
          CircleAvatar(
            radius: 20.r,
            backgroundColor: AppColors.scaffoldBackground,
            backgroundImage: chat.buyerAvatarUrl.isNotEmpty
                ? NetworkImage(chat.buyerAvatarUrl)
                : null,
            child: chat.buyerAvatarUrl.isEmpty
                ? Icon(Icons.person,
                    size: 22.sp, color: AppColors.grey400)
                : null,
          ),
          SizedBox(width: 10.w),

          // Name + order info
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
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EFFF),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        'Order ${chat.orderNumber}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5B5A99),
                        ),
                      ),
                    ),
                  ],
                ),
                if (chat.itemCount > 0)
                  Text(
                    '${chat.itemCount} Items \u2022 \u20A6${_formatNumber(chat.orderTotal)}',
                    style: AppTextStyle.bodySm.copyWith(
                      color: AppColors.textGrey,
                      fontSize: 12.sp,
                    ),
                  ),
              ],
            ),
          ),

          // Menu
          GestureDetector(
            onTap: () => showConversationMenu(
              context,
              notifier,
              chat,
            ),
            child: Icon(Icons.more_vert,
                size: 22.sp, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildResolvedBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      color: AppColors.scaffoldBackground,
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: AppColors.grey500,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'This conversation has ended. New messages are disabled.',
              style: AppTextStyle.bodySm.copyWith(
                color: AppColors.textGrey,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      MessageModel message, bool showSenderName) {
    final isMe = message.isMe;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender name label
          if (showSenderName) ...[
            Padding(
              padding: EdgeInsets.only(
                left: isMe ? 0 : 4.w,
                right: isMe ? 4.w : 0,
                bottom: 4.h,
              ),
              child: Text(
                message.senderName!,
                style: AppTextStyle.bodySm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                  fontSize: 11.sp,
                ),
              ),
            ),
          ],

          // Bubble
          Container(
            constraints: BoxConstraints(maxWidth: 280.w),
            padding: EdgeInsets.symmetric(
                horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isMe
                  ? AppColors.secondary500
                  : AppColors.scaffoldBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
                bottomLeft:
                    isMe ? Radius.circular(16.r) : Radius.circular(4.r),
                bottomRight:
                    isMe ? Radius.circular(4.r) : Radius.circular(16.r),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.text,
                  style: AppTextStyle.bodyMd.copyWith(
                    color: isMe ? AppColors.white : AppColors.textDark,
                    fontSize: 13.sp,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  message.time,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.sp,
                    color: isMe
                        ? AppColors.white.withOpacity(0.6)
                        : AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ChatModel chat) {
    final isDisabled = chat.isResolved;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.grey50,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Add button
          GestureDetector(
            onTap: isDisabled ? null : () {},
            child: Icon(
              Icons.add,
              size: 24.sp,
              color: isDisabled
                  ? AppColors.grey500.withOpacity(0.4)
                  : AppColors.secondary500,
            ),
          ),
          SizedBox(width: 12.w),

          // Text field
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: TextField(
                controller: _controller,
                enabled: !isDisabled,
                onSubmitted: (_) => _sendMessage(),
                style: AppTextStyle.bodyMd.copyWith(
                  fontSize: 13.sp,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: AppTextStyle.bodySm.copyWith(
                    color: isDisabled
                        ? AppColors.grey500.withOpacity(0.4)
                        : AppColors.textGrey,
                    fontSize: 13.sp,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    final formatted = number.toStringAsFixed(0);
    final result = StringBuffer();
    for (int i = 0; i < formatted.length; i++) {
      if (i > 0 && (formatted.length - i) % 3 == 0) {
        result.write(',');
      }
      result.write(formatted[i]);
    }
    return result.toString();
  }
}
