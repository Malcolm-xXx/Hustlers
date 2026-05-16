import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/dio_provider.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../data/datasources/discovery_remote_datasource.dart';
import '../../data/models/seller_model.dart';
import '../../data/repositories/discovery_repository_impl.dart';
import '../../domain/entities/home_feed_entity.dart';
import '../../domain/entities/seller_entity.dart';
import '../../domain/repositories/i_discovery_repository.dart';

final discoveryRemoteDatasourceProvider = Provider<DiscoveryRemoteDatasource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return DiscoveryRemoteDatasource(dioClient);
});

final discoveryRepositoryProvider = Provider<IDiscoveryRepository>((ref) {
  final datasource = ref.watch(discoveryRemoteDatasourceProvider);
  return DiscoveryRepositoryImpl(datasource);
});

final homeFeedProvider = FutureProvider<HomeFeedEntity>((ref) async {
  if (AppConstants.useMockData) {
    return HomeFeedEntity(
      categories: [],
      topSellers: SellerModel.mockSellers.map((m) => m.toEntity()).toList(),
      featuredProducts: [],
    );
  }
  return ref.watch(discoveryRepositoryProvider).getHomeFeed();
});

final discoverSellersProvider = FutureProvider<List<SellerEntity>>((ref) async {
  if (AppConstants.useMockData) {
    return SellerModel.mockSellers.map((m) => m.toEntity()).toList();
  }
  return ref.watch(discoveryRepositoryProvider).getDiscoverSellers();
});

final discoverItemsProvider = FutureProvider<List<ProductEntity>>((ref) async {
  if (AppConstants.useMockData) return [];
  return ref.watch(discoveryRepositoryProvider).getDiscoveryItems();
});

final discoverySearchProvider = FutureProvider.family<List<ProductEntity>, String>((ref, query) async {
  if (query.isEmpty) return [];
  return ref.watch(discoveryRepositoryProvider).search(query);
});
