import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/dio_provider.dart';
import '../../data/datasources/catalog_remote_datasource.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/catalog_repository_impl.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/tag_entity.dart';
import '../../domain/repositories/i_catalog_repository.dart';

final catalogRemoteDatasourceProvider = Provider<CatalogRemoteDatasource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return CatalogRemoteDatasource(dioClient);
});

final catalogRepositoryProvider = Provider<ICatalogRepository>((ref) {
  final datasource = ref.watch(catalogRemoteDatasourceProvider);
  return CatalogRepositoryImpl(datasource);
});

final categoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  return ref.watch(catalogRepositoryProvider).getCategories();
});

final tagsProvider = FutureProvider<List<TagEntity>>((ref) async {
  return ref.watch(catalogRepositoryProvider).getTags();
});

final productsProvider = FutureProvider.family<List<ProductEntity>, Map<String, dynamic>?>((ref, filters) async {
  if (AppConstants.useMockData) {
    return ProductModel.mockProducts.map((m) => m.toEntity()).toList();
  }
  return ref.watch(catalogRepositoryProvider).getProducts(filters: filters);
});

final productDetailsProvider = FutureProvider.family<ProductEntity, String>((ref, id) async {
  return ref.watch(catalogRepositoryProvider).getProductDetails(id);
});
