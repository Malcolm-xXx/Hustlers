import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../product/presentation/providers/catalog_provider.dart';
import '../../../product/domain/entities/product_entity.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_style.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../../core/widgets/instant_item_card.dart';
import '../../../product/data/models/product_model.dart';

class AvailableItemsSection extends ConsumerWidget {
  const AvailableItemsSection({super.key});

  void _navigateToProduct(BuildContext context, ProductEntity product) {
    context.pushNamed(
      RouteNames.productDetail,
      extra: product,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(productsProvider(null));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Instant Items',
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
              _buildFilterChip('Fresh Market'),
              const SizedBox(width: 8),
              _buildFilterChip('Grains'),
              const SizedBox(width: 8),
              _buildFilterChip('Oil/Spices'),
            ],
          ),
        ),

        // Grid of items
        productsState.when(
          data: (products) {
            if (products.isEmpty) return _buildEmptyItems();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return InstantItemCard(
                    name: product.title,
                    price: '₦${product.price}',
                    badge: product.badge ?? '',
                    badgeColor: AppColors.primary500,
                    onTap: () => _navigateToProduct(context, product),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildEmptyItems(),
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

  Widget _buildEmptyItems() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Icon(
            Icons.shopping_bag_outlined,
            size: 120,
            color: AppColors.grey400.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No Instant Items in Your Location',
            style: AppTextStyle.headingSm.copyWith(
              color: const Color(0xFF6B6B80),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Sellers in this area haven't listed any items for direct purchase yet. You can still get what you want by creating a list",
            textAlign: TextAlign.center,
            style: AppTextStyle.bodySm.copyWith(
              color: AppColors.grey500,
              height: 1.4,
            ),
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
                'Create a Custom List',
                style: AppTextStyle.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Check Nearby Areas',
            style: AppTextStyle.bodyMd.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }


}
