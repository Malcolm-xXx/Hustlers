import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/route_names.dart';
import '../../../../core/services/dio_provider.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../data/datasources/onboarding_remote_datasource.dart';
import '../../data/models/onboarding_page_model.dart';
import '../../domain/repositories/i_onboarding_repository.dart';
import '../../data/repositories/onboarding_repository_impl.dart';

final onboardingRemoteDatasourceProvider = Provider<OnboardingRemoteDatasource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return OnboardingRemoteDatasource(dioClient);
});

final onboardingRepositoryProvider = Provider<IOnboardingRepository>((ref) {
  final datasource = ref.watch(onboardingRemoteDatasourceProvider);
  return OnboardingRepositoryImpl(datasource);
});

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);

class OnboardingState {
  final List<OnboardingPageModel> pages;
  final int currentPage;

  const OnboardingState({
    required this.pages,
    this.currentPage = 0,
  });

  bool get isLastPage => currentPage == pages.length - 1;

  OnboardingState copyWith({
    List<OnboardingPageModel>? pages,
    int? currentPage,
  }) {
    return OnboardingState(
      pages: pages ?? this.pages,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    return OnboardingState(
      pages: OnboardingPageModel.defaultPages,
    );
  }

  void setPage(int index) {
    state = state.copyWith(currentPage: index);
  }

  Future<void> completeOnboarding(BuildContext context) async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setOnboardingComplete();

    if (context.mounted) {
      context.goNamed(RouteNames.roleSelection);
    }
  }


  Future<void> navigateToSignIn(BuildContext context) async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setOnboardingComplete();

    if (context.mounted) {
      context.goNamed(RouteNames.signIn);
    }
  }
}
