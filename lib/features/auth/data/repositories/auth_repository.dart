import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/dio_client.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import 'auth_repository_impl.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final dioClient = DioClient(tokenProvider: () => storage.accessToken);
  return AuthRepositoryImpl(AuthRemoteDatasource(dioClient));
});
