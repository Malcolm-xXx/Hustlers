import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_state_provider.dart';
import 'dio_client.dart';
import 'local_storage_service.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    tokenProvider: () => ref.read(localStorageServiceProvider).accessToken,
    onUnauthorized: () {
      ref.read(authStateProvider.notifier).expireSession();
    },
  );
});
