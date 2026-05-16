import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../data/models/chat_model.dart';
import '../providers/messaging_provider.dart';
import '../widgets/chat_avatar.dart';

class SearchChatView extends ConsumerStatefulWidget {
  const SearchChatView({super.key});

  @override
  ConsumerState<SearchChatView> createState() => _SearchChatViewState();
}

class _SearchChatViewState extends ConsumerState<SearchChatView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatSearchProvider);
    final notifier = ref.read(chatSearchProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 20.w, vertical: 12.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(Icons.arrow_back_ios_new,
                        size: 20.sp, color: AppColors.textDark),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Search Chat',
                    style: AppTextStyle.headingSm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 16.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.white100,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: _isFocused
                        ? AppColors.primary500
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search,
                        size: 20.sp, color: AppColors.textGrey),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: (v) =>
                            notifier.updateQuery(v),
                        onSubmitted: (_) => notifier.search(),
                        style: AppTextStyle.bodyMd.copyWith(
                          fontSize: 13.sp,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Search by name, order, or message...',
                          hintStyle: AppTextStyle.bodySm.copyWith(
                            color: AppColors.textGrey,
                            fontSize: 13.sp,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                    ),
                    if (state.query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _controller.clear();
                          notifier.clearSearch();
                        },
                        child: Icon(Icons.cancel,
                            size: 18.sp,
                            color: AppColors.grey500),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 8.h),

            // Content
            Expanded(
              child: state.hasSearched
                  ? _buildSearchResults(state, notifier)
                  : _buildInitialState(state, notifier),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildInitialState(
      ChatSearchState state, ChatSearchNotifier notifier) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      children: [
        // Recent Searches
        if (state.recentSearches.isNotEmpty) ...[
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(Icons.access_time,
                  size: 20.sp, color: AppColors.darkLight),
              SizedBox(width: 6.w),
              Text(
                'Recent Searches',
                style: AppTextStyle.labelMd.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...state.recentSearches.map((search) =>
              _buildRecentSearchItem(search, notifier)),
        ],

        // Suggested Chats
        if (state.suggestions.isNotEmpty) ...[
          SizedBox(height: 20.h),
          Row(
            children: [
              Icon(Icons.trending_up,
                  size: 16.sp, color: AppColors.primary500),
              SizedBox(width: 6.w),
              Text(
                'Suggested Chats',
                style: AppTextStyle.labelMd.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...state.suggestions
              .map((s) => _buildSuggestionItem(s)),
        ],

        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildRecentSearchItem(
      String search, ChatSearchNotifier notifier) {
    return GestureDetector(
      onTap: () {
        _controller.text = search;
        notifier.selectRecentSearch(search);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: AppColors.white100,
          borderRadius: BorderRadius.circular(14.r)
        ),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        child: Row(
          children: [
            Icon(Icons.access_time,
                size: 18.sp, color: AppColors.darkLight),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                search,
                style: AppTextStyle.bodyMd.copyWith(
                  fontSize: 14.sp,
                ),
              ),
            ),
            Icon(Icons.north_west,
                size: 16.sp, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(ChatSearchSuggestion suggestion) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          ChatAvatar(),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.name,
                  style: AppTextStyle.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
                Text(
                  suggestion.subtitle,
                  style: AppTextStyle.bodySm.copyWith(
                    color: AppColors.textGrey,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.north_west,
              size: 16.sp, color: AppColors.textGrey),
        ],
      ),
    );
  }

  // ─── SEARCH RESULTS ───

  Widget _buildSearchResults(
      ChatSearchState state, ChatSearchNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h,),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.results.length} result${state.results.length == 1 ? '' : 's'} found',
                style: AppTextStyle.bodySm.copyWith(
                  fontWeight: FontWeight.w500,
                  color: state.results.isNotEmpty
                      ? AppColors.darkLight
                      : AppColors.darkLight,
                  fontSize: 12.sp,
                ),
              ),
              GestureDetector(
                onTap: state.results.isNotEmpty
                    ? () => notifier.clearHistory()
                    : null,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      width: 1.15,
                      color: state.results.isNotEmpty
                          ? AppColors.white200
                          : AppColors.white200,
                    ),
                  ),
                  child: Text(
                    'Clear History',
                    style: AppTextStyle.bodySm.copyWith(
                      fontWeight: FontWeight.w500,
                      color: state.results.isNotEmpty
                          ? AppColors.textDark
                          : AppColors.textGrey,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 8.h),

        // Results or empty state
        Expanded(
          child: state.results.isNotEmpty
              ? _buildResultsList(state.results)
              : _buildNoResults(state.query, notifier),
        ),
      ],
    );
  }

  Widget _buildResultsList(List<ChatSearchResult> results) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Row(
            children: [
              // Avatar
              ChatAvatar(),
              SizedBox(width: 12.w),

              // Name, order, message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          result.name,
                          style: AppTextStyle.labelMd.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.primary100,
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Text(
                            'Order ${result.orderNumber}',
                            style: AppTextStyle.bodySm.copyWith(
                              fontFamily: 'Poppins',
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.hash,
                            ),
                          ),
                        ),

                        SizedBox(width: 6.w),
                        Container(
                          width: 7.w,
                          height: 7.w,
                          decoration: BoxDecoration(
                            color: AppColors.grey500,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      result.message,
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

              // Time ago
              Text(
                result.timeAgo,
                style: AppTextStyle.bodySm.copyWith(
                  color: AppColors.textGrey,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoResults(String query, ChatSearchNotifier notifier) {
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
                Icons.search,
                size: 56.sp,
                color: AppColors.grey500.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              "We Couldn\u2019t Find That",
              style: AppTextStyle.bodyLg.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.secondary100,
              ),
            ),
            SizedBox(height: 8.h),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyle.bodyMd.copyWith(
                  color: AppColors.textGrey,
                  fontSize: 13.sp,
                ),
                children: [
                  TextSpan(
                      style: AppTextStyle.bodyMd.copyWith(
                          color: AppColors.secondary50,
                          fontSize: 14.sp
                      ),
                      text: 'No message match \u201C'),
                  TextSpan(
                    text: query,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary50),
                  ),
                  TextSpan(
                    style: AppTextStyle.bodyMd.copyWith(
                      color: AppColors.secondary50,
                      fontSize: 14.sp
                    ),
                      text:
                          '\u201D. Try checking your spelling or search for something else'),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: 200.w,
              child: ElevatedButton(
                onPressed: () {
                  _controller.clear();
                  notifier.clearSearch();
                },
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
                  'Clear Search',
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
