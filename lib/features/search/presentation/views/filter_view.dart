import 'package:flutter/material.dart';
import 'package:hustlers/core/constants/app_colors.dart';
import 'package:hustlers/core/constants/app_text_style.dart';

class FilterView extends StatefulWidget {
  const FilterView({super.key});

  @override
  State<FilterView> createState() => _FilterViewState();
}

class _FilterViewState extends State<FilterView> {
  // Expansion states
  bool _isCategoryExpanded = true;
  bool _isSellerExpanded = true;
  bool _isBudgetExpanded = true;
  bool _isDistanceExpanded = true;

  // Filter selections
  String _selectedCategory = 'Fresh Market';
  String _selectedSeller = 'Jude Simon';
  double _budgetMin = 10;
  double _budgetMax = 100000;
  String _selectedDistance = 'Within 500m';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Filter',
          style: AppTextStyle.headingSm.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              // Reset all
              setState(() {
                _selectedCategory = '';
                _selectedSeller = '';
                _selectedDistance = '';
              });
            },
            child: Text(
              'Reset All',
              style: AppTextStyle.bodyMd.copyWith(
                color: AppColors.primary500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildCategorySection(),
                  const Divider(color: Color(0xFFF0F0F0), height: 32),
                  _buildSellerSection(),
                  const Divider(color: Color(0xFFF0F0F0), height: 32),
                  _buildBudgetSection(),
                  const Divider(color: Color(0xFFF0F0F0), height: 32),
                  _buildDistanceSection(),
                  const SizedBox(height: 120), // Space for bottom button
                ],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B1A28), // Dark color
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Text(
                'Show results (4)',
                style: AppTextStyle.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? subtitle,
    required bool isExpanded,
    required VoidCallback onTap,
    int? activeCount,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppTextStyle.bodyMd.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    if (activeCount != null && activeCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary500,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          activeCount.toString(),
                          style: AppTextStyle.bodySm.copyWith(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyle.bodySm.copyWith(
                      color: AppColors.grey500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: AppColors.textDark,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    final categories = [
      'All',
      'Fresh Market',
      'Staples',
      'Drinks',
      'Snacks',
      'Breakfast',
      'Spices',
      'Cooked Food',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Category',
          isExpanded: _isCategoryExpanded,
          onTap: () {
            setState(() {
              _isCategoryExpanded = !_isCategoryExpanded;
            });
          },
          activeCount: _selectedCategory.isNotEmpty ? 1 : null,
        ),
        if (_isCategoryExpanded) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary500
                        : const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    cat,
                    style: AppTextStyle.bodySm.copyWith(
                      color: isSelected ? AppColors.white : AppColors.grey500,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSellerSection() {
    final sellers = [
      {'name': 'Mama Ngozi', 'image': 'https://i.pravatar.cc/150?img=5'},
      {'name': 'Jude Simon', 'image': 'https://i.pravatar.cc/150?img=11'},
      {'name': 'Sisi Philips', 'image': 'https://i.pravatar.cc/150?img=9'},
      {'name': 'The Drink Plug', 'image': 'https://i.pravatar.cc/150?img=12'},
      {
        'name': 'Ifeanyi Bulk Store',
        'image': 'https://i.pravatar.cc/150?img=13',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Specific Seller',
          subtitle: 'Only Shows Huslters from your Favourites',
          isExpanded: _isSellerExpanded,
          onTap: () {
            setState(() {
              _isSellerExpanded = !_isSellerExpanded;
            });
          },
          activeCount: _selectedSeller.isNotEmpty ? 1 : null,
        ),
        if (_isSellerExpanded) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              // All Sellers button
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8), // align with avatars
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSeller = 'All';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedSeller == 'All'
                            ? AppColors.primary500
                            : const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'All Sellers',
                        style: AppTextStyle.bodySm.copyWith(
                          color: _selectedSeller == 'All'
                              ? AppColors.white
                              : AppColors.grey500,
                          fontWeight: _selectedSeller == 'All'
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ...sellers.map((seller) {
                final isSelected = _selectedSeller == seller['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSeller = seller['name']!;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSelected ? 3 : 0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.primary500,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundImage: NetworkImage(seller['image']!),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        seller['name']!,
                        style: AppTextStyle.bodySm.copyWith(
                          fontSize: 11,
                          color: isSelected
                              ? AppColors.primary500
                              : AppColors.textDark,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBudgetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Budget (₦)',
          isExpanded: _isBudgetExpanded,
          onTap: () {
            setState(() {
              _isBudgetExpanded = !_isBudgetExpanded;
            });
          },
        ),
        if (_isBudgetExpanded) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₦10',
                style: AppTextStyle.bodySm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '₦100,000',
                style: AppTextStyle.bodySm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary500,
              inactiveTrackColor: const Color(0xFFFFF6ED),
              thumbColor: AppColors.primary500,
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: RangeSlider(
              values: RangeValues(_budgetMin, _budgetMax),
              min: 10,
              max: 100000,
              onChanged: (RangeValues values) {
                setState(() {
                  _budgetMin = values.start;
                  _budgetMax = values.end;
                });
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDistanceSection() {
    final distances = ['Anywhere', 'Within 500m', 'Within 1km', 'Within 2km'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title:
              'Seller Distance', // Keeping Seller Distance based on image 108
          isExpanded: _isDistanceExpanded,
          onTap: () {
            setState(() {
              _isDistanceExpanded = !_isDistanceExpanded;
            });
          },
          activeCount: _selectedDistance.isNotEmpty ? 1 : null,
        ),
        if (_isDistanceExpanded) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: distances.map((dist) {
              final isSelected = _selectedDistance == dist;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDistance = dist;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary500
                        : const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dist,
                    style: AppTextStyle.bodySm.copyWith(
                      color: isSelected
                          ? AppColors.white
                          : const Color(0xFFB9B9B9),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
