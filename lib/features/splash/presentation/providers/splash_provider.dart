import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/local_storage_service.dart';

final hasCompletedOnboardingProvider = Provider<bool>((ref) {
  return ref.watch(localStorageServiceProvider).hasCompletedOnboarding;
});
