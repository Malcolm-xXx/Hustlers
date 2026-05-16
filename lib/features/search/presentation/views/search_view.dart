import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hustlers/core/constants/app_colors.dart';
import 'package:hustlers/core/constants/app_text_style.dart';
import 'package:hustlers/core/widgets/instant_item_card.dart';
import '../../../home/presentation/providers/discovery_provider.dart';
import '../../../product/domain/entities/product_entity.dart';
import 'filter_view.dart';
import 'package:flutter/material.dart';
enum SearchState { initial, typing, results }

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  SearchState _state = SearchState.initial;

  // Dummy recent searches
  final List<Map<String, dynamic>> _recentSearches = [
    {'type': 'text', 'title': 'Local Rice'},
    {'type': 'text', 'title': 'Pepper'},
    {'type': 'text', 'title': 'Yellow Garri'},
    {
      'type': 'user',
      'title': 'John Doe',
      'image': 'https://i.pravatar.cc/150?img=11',
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);

    // Auto focus when opened if we want
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty && _state == SearchState.initial) {
      setState(() {
        _state = SearchState.typing;
      });
    } else if (_searchController.text.isEmpty &&
        _state != SearchState.initial) {
      setState(() {
        _state = SearchState.initial;
      });
    }
  }

  void _onFocusChanged() {
    if (_searchFocusNode.hasFocus && _state == SearchState.results) {
      setState(() {
        _state = _searchController.text.isEmpty
            ? SearchState.initial
            : SearchState.typing;
      });
    }
  }

  void _onSubmit(String value) {
    if (value.isNotEmpty) {
      setState(() {
        _state = SearchState.results;
        _searchFocusNode.unfocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
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
          'Search',
          style: AppTextStyle.headingSm.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search, color: Color(0xFFB9B9B9), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onSubmitted: _onSubmit,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search food item, hustler, loc...',
                        hintStyle: AppTextStyle.bodyMd.copyWith(
                          color: const Color(0xFFB9B9B9),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.only(bottom: 4),
                      ),
                      style: AppTextStyle.bodyMd,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FilterView()),
              );
            },
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1B1A28),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune, color: AppColors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case SearchState.initial:
      case SearchState.typing:
        return _buildRecentSearches();
      case SearchState.results:
        final searchResults = ref.watch(discoverySearchProvider(_searchController.text));
        return searchResults.when(
          data: (products) => _buildResults(products),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        );
    }
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'RECENT SEARCHES',
            style: AppTextStyle.bodySm.copyWith(
              color: const Color(0xFF1B1A28),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _recentSearches.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final item = _recentSearches[index];
                return Row(
                  children: [
                    if (item['type'] == 'user') ...[
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(item['image']),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        item['title'],
                        style: AppTextStyle.bodyMd.copyWith(
                          color: const Color(0xFF333333),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _recentSearches.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF999999),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.white,
                          size: 10,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List<ProductEntity> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${products.length} Results',
                style: AppTextStyle.headingSm.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.swap_vert,
                      size: 14,
                      color: Color(0xFF888888),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Sort',
                      style: AppTextStyle.bodySm.copyWith(
                        color: const Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Color(0xFF888888),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: products.isEmpty 
          ? Center(
              child: Text(
                'No results found for "${_searchController.text}"',
                style: AppTextStyle.bodyMd.copyWith(color: AppColors.grey500),
              ),
            )
          : GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.68,
            ),
            padding: const EdgeInsets.all(24),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return InstantItemCard(
                name: product.title,
                price: '₦${product.price}',
                badge: product.badge!,
                badgeColor: AppColors.primary500,
              );
            },
          ),
        ),
      ],
    );
  }
}
