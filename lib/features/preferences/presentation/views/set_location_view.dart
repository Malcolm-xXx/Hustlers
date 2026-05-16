import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/auth_header.dart';
import '../providers/preferences_provider.dart';
import '../widgets/location_access_dialog.dart';
import '../widgets/preference_progress_bar.dart';

class SetLocationView extends ConsumerStatefulWidget {
  const SetLocationView({super.key});

  @override
  ConsumerState<SetLocationView> createState() => _SetLocationViewState();
}

class _SetLocationViewState extends ConsumerState<SetLocationView> {
  late TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearching = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  const AuthHeader(),
                  const PreferenceProgressBar(currentStep: 2),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  _buildMapBackground(),
                  _buildBottomSheet(state, notifier),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBackground() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.fieldBackground.withOpacity(0.5),
      ),
      child: CustomPaint(
        painter: _MapPatternPainter(),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildBottomSheet(PreferencesState state, PreferencesNotifier notifier) {
    return DraggableScrollableSheet(
      initialChildSize: _isSearching ? 0.85 : 0.65,
      minChildSize: 0.55,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 12.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.dotInactive,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Center(
                child: Text(
                  'Set Your Location',
                  style: AppTextStyle.headingMd.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: _buildSearchField(state, notifier),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: _buildUseCurrentLocation(notifier),
              ),
              if (state.locationSuggestions.isNotEmpty && state.location == null)
                _buildSuggestionsList(state, notifier),
              if (state.locationSuggestions.isEmpty && state.location == null)
                _buildEmptyState(),
              SizedBox(height: 24.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: AppPrimaryButton(
                  text: state.isLocationSelected ? 'Done' : 'Next',
                  isLoading: state.isLoading,
                  onPressed: state.isLocationSelected
                      ? () => notifier.navigateToHome(context)
                      : null,
                  backgroundColor: state.isLocationSelected
                      ? AppColors.secondary500
                      : AppColors.buttonDisabled,
                  disabledBackgroundColor: AppColors.buttonDisabled,
                  disabledForegroundColor: AppColors.white,
                  borderRadius: 26.r,
                  height: 52.h,
                ),
              ),
              SizedBox(height: 12.h),
              Center(
                child: GestureDetector(
                  onTap: () => notifier.skipToNext(context),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Text(
                      'Skip',
                      style: AppTextStyle.labelMd.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchField(PreferencesState state, PreferencesNotifier notifier) {
    return Container(
      height: 52.h,
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: _searchFocusNode.hasFocus
              ? AppColors.primary500
              : AppColors.fieldBorderInactive.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) {
                notifier.setLocationQuery(value);
              },
              style: AppTextStyle.bodyMd.copyWith(
                fontSize: 14.sp,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                hintText: 'Select Your Location',
                hintStyle: AppTextStyle.hint.copyWith(
                  fontSize: 14.sp,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary500,
              ),
              child: Icon(
                Icons.navigation_rounded,
                color: AppColors.white,
                size: 18.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUseCurrentLocation(PreferencesNotifier notifier) {
    return GestureDetector(
      onTap: () async {
        final result = await LocationAccessDialog.show(context);
        if (result == true) {
          notifier.setLocation('Current Location');
          _searchController.text = 'Current Location';
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: const Color(0xFF4CAF50),
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Use your current Location',
                style: AppTextStyle.bodyMd.copyWith(
                  fontSize: 14.sp,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textDark,
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList(
      PreferencesState state, PreferencesNotifier notifier) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: state.locationSuggestions.map((suggestion) {
          return GestureDetector(
            onTap: () {
              notifier.selectLocationSuggestion(suggestion);
              _searchController.text = suggestion;
              _searchFocusNode.unfocus();
            },
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: AppColors.textGrey,
                    size: 18.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: AppTextStyle.bodyMd.copyWith(
                        fontSize: 13.sp,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.only(top: 32.h),
      child: Column(
        children: [
          Icon(
            Icons.location_searching_rounded,
            size: 56.sp,
            color: AppColors.dotInactive,
          ),
          SizedBox(height: 16.h),
          Text(
            'Search for your location',
            style: AppTextStyle.labelMd.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Your searched location suggestions shows up here',
            style: AppTextStyle.bodySm.copyWith(
              fontSize: 12.sp,
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8E8E8).withOpacity(0.5)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (double i = 0; i < size.width; i += 60) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 60) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    final textPaint = Paint()
      ..color = const Color(0xFFD0D0D0).withOpacity(0.6)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.3, size.height * 0.05);
    path.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.15,
      size.width * 0.9,
      size.height * 0.1,
    );
    canvas.drawPath(path, textPaint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.2);
    path2.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.25,
      size.width * 0.8,
      size.height * 0.18,
    );
    canvas.drawPath(path2, textPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
