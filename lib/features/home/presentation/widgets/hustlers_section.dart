import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../domain/entities/seller_entity.dart';
import '../providers/discovery_provider.dart';

class HustlersSection extends ConsumerWidget {
  const HustlersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellersState = ref.watch(discoverSellersProvider);
    final bool isEmptyState = false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hustlers in Your Location',
                style: AppTextStyle.headingSm.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'See all',
                style: AppTextStyle.bodySm.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip('All', isSelected: true),
              const SizedBox(width: 8),
              _buildFilterChip('My Favourites'),
              const SizedBox(width: 8),
              _buildFilterChip('In Market'),
              const SizedBox(width: 8),
              _buildFilterChip('Top Rated'),
            ],
          ),
        ),

        sellersState.when(
          data: (sellers) {
            if (sellers.isEmpty) return _buildEmptyHustlers();
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: sellers.length,
              itemBuilder: (context, index) {
                return _buildHustlerCard(sellers[index]);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildEmptyHustlers(),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFF6ED) : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyle.bodySm.copyWith(
          color: isSelected ? AppColors.primary500 : AppColors.grey500,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildHustlerCard(SellerEntity seller) {
    List<String> tags = seller.tags;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with tick
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: NetworkImage(
                  seller.profileImageUrl ?? 'https://i.pravatar.cc/150?img=11',
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary500,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      seller.name,
                      style: AppTextStyle.bodyMd.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.star,
                      color: AppColors.starYellow,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      seller.rating.toString(),
                      style: AppTextStyle.bodySm.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '(${seller.totalReviews})',
                      style: AppTextStyle.bodySm.copyWith(
                        color: AppColors.grey400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.textDark,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${seller.status} • ${seller.distance}',
                          style: AppTextStyle.bodySm.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),


                    Row(
                      children: [
                        Container(
                          width: 26.w,
                          height: 26.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white
                          ),
                          child: Icon(
                            Icons.favorite_border,
                            color: AppColors.grey500,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 10.w),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary500,
                            border: Border.all(color: AppColors.textDark),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Send List',
                            style: AppTextStyle.bodySm.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.white
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: tags
                      .map(
                        (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: AppTextStyle.bodySm.copyWith(
                          fontSize: 10,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHustlers() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.location_off_outlined,
            size: 120,
            color: AppColors.grey400.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Quiet Zone',
            style: AppTextStyle.headingSm.copyWith(
              color: const Color(0xFF6B6B80), // Muted purple/gray
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no Hustlers active in your area right now',
            textAlign: TextAlign.center,
            style: AppTextStyle.bodySm.copyWith(color: AppColors.grey500),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B1A28),
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Text(
                'Notify me when someone is online',
                style: AppTextStyle.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Change Location',
            style: AppTextStyle.bodyMd.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }


}
