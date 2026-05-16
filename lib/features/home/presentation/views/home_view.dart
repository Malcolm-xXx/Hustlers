import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hustlers/core/constants/app_colors.dart';
import 'package:hustlers/core/constants/app_text_style.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import '../providers/discovery_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/available_items_section.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/hustlers_section.dart';
import '../widgets/verification_banner.dart';
import '../widgets/wallet_card.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final bool _isEmptyState = false;

  @override
  Widget build(BuildContext context) {
    final homeFeedState = ref.watch(homeFeedProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.white,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(homeFeedProvider);
            return ref.read(homeFeedProvider.future);
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeAppBar(scaffoldKey: _scaffoldKey),
                const HomeSearchBar(),
                const WalletCard(),
                const VerificationBanner(),
                const HustlersSection(),
                const AvailableItemsSection(),
                const SizedBox(height: 100),
              ]
                  .animate(interval: 80.ms)
                  .fade(duration: 500.ms)
                  .slideY(
                    begin: 0.1,
                    duration: 500.ms,
                    curve: Curves.easeOutQuad,
                  ),
            ),
          ),
        ),
      ),
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

  Widget _buildHustlerCard(Map<String, dynamic> data) {
    List<String> tags = data['tags'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with tick
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?img=11',
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
                          data['name'],
                          style: AppTextStyle.bodyMd.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
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
                          '4.8',
                          style: AppTextStyle.bodySm.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '(230)',
                          style: AppTextStyle.bodySm.copyWith(
                            color: AppColors.grey400,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.textDark,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${data['status']} • ${data['distance']}',
                          style: AppTextStyle.bodySm.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                                color: const Color(0xFFFFF6ED),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tag,
                                style: AppTextStyle.bodySm.copyWith(
                                  fontSize: 10,
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w600,
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

          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.favorite_border,
              color: AppColors.grey500,
              size: 20,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textDark),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Send List',
                style: AppTextStyle.bodySm.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


}
