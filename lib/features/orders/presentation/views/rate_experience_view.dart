import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../data/models/order_model.dart';
import '../providers/orders_provider.dart';

class RateExperienceView extends ConsumerStatefulWidget {
  final OrderModel order;

  const RateExperienceView({super.key, required this.order});

  @override
  ConsumerState<RateExperienceView> createState() =>
      _RateExperienceViewState();
}

class _RateExperienceViewState extends ConsumerState<RateExperienceView> {
  final _commentController = TextEditingController();
  bool _showCongrats = true;

  static const _feedbackTags = [
    {'icon': Icons.flash_on_outlined, 'label': 'Fast Delivery'},
    {'icon': Icons.auto_awesome_outlined, 'label': 'Great Quality'},
    {'icon': Icons.workspace_premium_outlined, 'label': 'Professional'},
    {'icon': Icons.emoji_emotions_outlined, 'label': 'Friendly'},
    {'icon': Icons.chat_outlined, 'label': 'Good Communication'},
    {'icon': Icons.monetization_on_outlined, 'label': 'Fair Pricing'},
    {'icon': Icons.inventory_2_outlined, 'label': 'Clean Packaging'},
    {'icon': Icons.timer_outlined, 'label': 'On Time'},
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rateExperienceProvider);
    final notifier = ref.read(rateExperienceProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Congrats banner
            if (_showCongrats)
              _buildCongratsBanner(),

            // App bar
            if (!_showCongrats)
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Icon(Icons.arrow_back_ios_new,
                          size: 20.sp, color: AppColors.textDark),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rate Your Experience',
                            style: AppTextStyle.headingSm.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Order ${widget.order.orderNumber}',
                            style: AppTextStyle.bodySm.copyWith(
                              color: AppColors.textGrey,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showSkipDialog(context),
                      child: Text(
                        'Skip',
                        style: AppTextStyle.labelMd.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8.h),

                    // Hustler info + total
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22.r,
                          backgroundColor: AppColors.grey50,
                          child: Icon(Icons.person,
                              size: 24.sp, color: AppColors.grey400),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.order.hustlerName,
                                style: AppTextStyle.labelMd.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Your Hustler',
                                style: AppTextStyle.bodySm.copyWith(
                                  color: AppColors.textGrey,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Order Total: \u20A6${widget.order.total.toStringAsFixed(0)}',
                          style: AppTextStyle.labelMd.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary600,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24.h),

                    // Rating card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'How was your experience?',
                            style: AppTextStyle.labelLg.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Tap to rate your experience',
                            style: AppTextStyle.bodySm.copyWith(
                              color: AppColors.textGrey,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Stars
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final isSelected =
                                  index < state.starRating;
                              return GestureDetector(
                                onTap: () =>
                                    notifier.setStarRating(index + 1),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 4.w),
                                  child: Icon(
                                    isSelected
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 44.sp,
                                    color: isSelected
                                        ? AppColors.primary500
                                        : AppColors.grey500,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 28.h),

                    // Quick Feedback Tags
                    Text(
                      'Quick Feedback Tags',
                      style: AppTextStyle.labelLg.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Tags grid (2 columns)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        childAspectRatio: 3.2,
                      ),
                      itemCount: _feedbackTags.length,
                      itemBuilder: (context, index) {
                        final tag = _feedbackTags[index];
                        final label = tag['label'] as String;
                        final icon = tag['icon'] as IconData;
                        final isSelected =
                            state.selectedTags.contains(label);

                        return GestureDetector(
                          onTap: () => notifier.toggleTag(label),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary500
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary500
                                    : AppColors.grey50,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  icon,
                                  size: 18.sp,
                                  color: isSelected
                                      ? AppColors.textDark
                                      : AppColors.textGrey,
                                ),
                                SizedBox(width: 6.w),
                                Flexible(
                                  child: Text(
                                    label,
                                    style: AppTextStyle.bodySm.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? AppColors.textDark
                                          : AppColors.textDark,
                                      fontSize: 12.sp,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 28.h),

                    // Additional Comments
                    Row(
                      children: [
                        Text(
                          'Additional Comments',
                          style: AppTextStyle.labelLg.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '(Optional)',
                          style: AppTextStyle.bodySm.copyWith(
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: TextField(
                        controller: _commentController,
                        maxLines: 4,
                        maxLength: 250,
                        onChanged: notifier.setComment,
                        style: AppTextStyle.bodyMd,
                        decoration: InputDecoration(
                          hintText:
                              'Tell us more about your experience...',
                          hintStyle: AppTextStyle.bodyMd.copyWith(
                            color:
                                AppColors.textGrey.withOpacity(0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16.w),
                          counterStyle: AppTextStyle.bodySm.copyWith(
                            color: AppColors.textGrey,
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),

            // Submit button
            Container(
              padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 16.h),
              color: Colors.white,
              child: Column(
                children: [
                  AppPrimaryButton(
                    text: 'Submit Review',
                    icon: Icon(Icons.send,
                        size: 18.sp, color: AppColors.white),
                    onPressed: state.canSubmit && !state.isSubmitting
                        ? () async {
                            await ref
                                .read(rateExperienceProvider.notifier)
                                .submitRating(widget.order.id);
                            if (!context.mounted) return;
                            _showReviewSentDialog(context);
                          }
                        : null,
                    isLoading: state.isSubmitting,
                    backgroundColor: state.canSubmit
                        ? AppColors.secondary500
                        : AppColors.buttonDisabled,
                    disabledBackgroundColor: AppColors.buttonDisabled,
                    disabledForegroundColor: AppColors.white,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Your review helps improve our community',
                    style: AppTextStyle.bodySm.copyWith(
                      color: AppColors.textGrey,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCongratsBanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.h,
            decoration: const BoxDecoration(
              color: AppColors.successIcon,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check,
                size: 20.sp, color: AppColors.white),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Congratulations!',
                  style: AppTextStyle.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Your item has been successfully delivered',
                  style: AppTextStyle.bodySm.copyWith(
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showCongrats = false),
            child: Icon(Icons.close,
                size: 20.sp, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  void _showSkipDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 40.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Skip Review?',
              style: AppTextStyle.headingMd.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Are you sure you want to skip the review?\nIt helps improve our community',
              style: AppTextStyle.bodyMd.copyWith(
                color: AppColors.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(rateExperienceProvider.notifier).reset();
                  context.pop(); // Go back from rate screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.logOutRed,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Yes, skip review',
                  style: AppTextStyle.bodyLg.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text(
                'No, don\'t skip',
                style: AppTextStyle.bodyLg.copyWith(
                  color: AppColors.verifiedGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewSentDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(28.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Star icon with glow
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80.w,
                    height: 80.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary100,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 56.w,
                    height: 56.h,
                    decoration: const BoxDecoration(
                      color: AppColors.primary500,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.star,
                        size: 30.sp, color: AppColors.white),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Text(
                'Your review has been sent!',
                style: AppTextStyle.headingSm.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Thank you for reviewing! The seller has been notified',
                style: AppTextStyle.bodyMd.copyWith(
                  color: AppColors.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    ref.read(rateExperienceProvider.notifier).reset();
                    context.pop(); // Go back from rate screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary500,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Done',
                    style: AppTextStyle.bodyLg.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
