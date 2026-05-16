import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/errors/app_error_handler.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../auth/presentation/providers/sign_up_provider.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';

final preferencesProvider =
    NotifierProvider<PreferencesNotifier, PreferencesState>(
        PreferencesNotifier.new);

class PreferencesState {
  final int currentStep;
  final String? primaryGoal;
  final String? cookingPreference;
  final String? location;
  final bool isLoading;
  final String? error;
  final String locationQuery;
  final List<String> locationSuggestions;

  const PreferencesState({
    this.currentStep = 0,
    this.primaryGoal,
    this.cookingPreference,
    this.location,
    this.isLoading = false,
    this.error,
    this.locationQuery = '',
    this.locationSuggestions = const [],
  });

  bool get isPrimaryGoalSelected => primaryGoal != null;
  bool get isCookingPreferenceSelected => cookingPreference != null;
  bool get isLocationSelected => location != null && location!.isNotEmpty;

  PreferencesState copyWith({
    int? currentStep,
    String? primaryGoal,
    String? cookingPreference,
    String? location,
    bool? isLoading,
    String? error,
    String? locationQuery,
    List<String>? locationSuggestions,
  }) {
    return PreferencesState(
      currentStep: currentStep ?? this.currentStep,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      cookingPreference: cookingPreference ?? this.cookingPreference,
      location: location ?? this.location,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      locationQuery: locationQuery ?? this.locationQuery,
      locationSuggestions: locationSuggestions ?? this.locationSuggestions,
    );
  }
}

class PreferencesNotifier extends Notifier<PreferencesState> {
  @override
  PreferencesState build() => const PreferencesState();

  void selectPrimaryGoal(String goal) {
    state = state.copyWith(primaryGoal: goal);
  }

  void selectCookingPreference(String preference) {
    state = state.copyWith(cookingPreference: preference);
  }

  void setLocation(String location) {
    state = state.copyWith(location: location);
  }

  void setLocationQuery(String query) {
    state = state.copyWith(locationQuery: query);
    if (query.isNotEmpty) {
      state = state.copyWith(
        locationSuggestions: [
          '$query, Ibadan, Nigeria',
          '$query, zoo and museum Ibadan, Nigeria',
          '$query, Health Center Ibadan, Nigeria',
        ],
      );
    } else {
      state = state.copyWith(locationSuggestions: []);
    }
  }

  void selectLocationSuggestion(String suggestion) {
    state = state.copyWith(
      location: suggestion,
      locationQuery: suggestion,
      locationSuggestions: [],
    );
  }

  void navigateToPrimaryGoal(BuildContext context) {
    state = state.copyWith(currentStep: 0);
    if (context.mounted) {
      context.goNamed(RouteNames.primaryGoal);
    }
  }

  void navigateToCookingPreference(BuildContext context) {
    state = state.copyWith(currentStep: 1);
    if (context.mounted) {
      context.goNamed(RouteNames.cookingPreference);
    }
  }

  void navigateToSetLocation(BuildContext context) {
    state = state.copyWith(currentStep: 2);
    if (context.mounted) {
      context.goNamed(RouteNames.setLocation);
    }
  }

  void skipToNext(BuildContext context) {
    switch (state.currentStep) {
      case 0:
        navigateToCookingPreference(context);
        break;
      case 1:
        navigateToSetLocation(context);
        break;
      case 2:
        navigateToHome(context);
        break;
    }
  }

  Future<void> navigateToHome(BuildContext context) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final role = ref.read(signUpProvider).selectedRole ?? 'buyer';
      final onboardingRepo = ref.read(onboardingRepositoryProvider);

      await onboardingRepo.completeOnboarding(
        onboardingData: {
          'role': role,
          'primary_goal': state.primaryGoal,
          'cooking_preference': state.cookingPreference,
        },
        formattedAddress: state.location,
      );

      state = state.copyWith(isLoading: false);

      if (context.mounted) {
        if (role == 'seller') {
          context.goNamed(RouteNames.idVerification);
        } else {
          context.goNamed(RouteNames.home);
        }
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Something went wrong. Please try again.');
    }
  }
}
