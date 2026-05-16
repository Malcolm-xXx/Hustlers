import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/errors/app_error_handler.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../../core/services/dio_provider.dart';
import '../../data/datasources/verification_remote_datasource.dart';
import '../../domain/repositories/i_verification_repository.dart';
import '../../data/repositories/verification_repository_impl.dart';

final verificationRemoteDatasourceProvider = Provider<VerificationRemoteDatasource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return VerificationRemoteDatasource(dioClient);
});

final verificationRepositoryProvider = Provider<IVerificationRepository>((ref) {
  final datasource = ref.watch(verificationRemoteDatasourceProvider);
  return VerificationRepositoryImpl(datasource);
});

final verificationProvider =
    NotifierProvider<VerificationNotifier, VerificationState>(
        VerificationNotifier.new);

final verificationStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(verificationRepositoryProvider).getVerificationStatus();
});

enum IdType { id_card, nin, drivers_license, passport }

enum VerificationStep { selectId, faceId, complete }

enum BannerType { success, error }

class BannerState {
  final BannerType type;
  final String title;
  final String message;

  const BannerState({
    required this.type,
    required this.title,
    required this.message,
  });
}

class VerificationState {
  final IdType? selectedIdType;
  final int currentStep;
  final bool isLoading;
  final BannerState? banner;
  final bool idUploaded;
  final bool faceScanned;
  
  // Metadata for final submission
  final String? idImageUrl;
  final String? idImagePublicId;
  final String? selfieImageUrl;
  final String? selfieImagePublicId;

  const VerificationState({
    this.selectedIdType,
    this.currentStep = 0,
    this.isLoading = false,
    this.banner,
    this.idUploaded = false,
    this.faceScanned = false,
    this.idImageUrl,
    this.idImagePublicId,
    this.selfieImageUrl,
    this.selfieImagePublicId,
  });

  VerificationState copyWith({
    IdType? selectedIdType,
    int? currentStep,
    bool? isLoading,
    BannerState? banner,
    bool clearBanner = false,
    bool? idUploaded,
    bool? faceScanned,
    String? idImageUrl,
    String? idImagePublicId,
    String? selfieImageUrl,
    String? selfieImagePublicId,
  }) {
    return VerificationState(
      selectedIdType: selectedIdType ?? this.selectedIdType,
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      banner: clearBanner ? null : (banner ?? this.banner),
      idUploaded: idUploaded ?? this.idUploaded,
      faceScanned: faceScanned ?? this.faceScanned,
      idImageUrl: idImageUrl ?? this.idImageUrl,
      idImagePublicId: idImagePublicId ?? this.idImagePublicId,
      selfieImageUrl: selfieImageUrl ?? this.selfieImageUrl,
      selfieImagePublicId: selfieImagePublicId ?? this.selfieImagePublicId,
    );
  }
}

class VerificationNotifier extends Notifier<VerificationState> {
  @override
  VerificationState build() => const VerificationState();

  void selectIdType(IdType type) {
    state = state.copyWith(selectedIdType: type);
  }

  void showSuccessBanner(String title, String message) {
    state = state.copyWith(
      banner: BannerState(
        type: BannerType.success,
        title: title,
        message: message,
      ),
    );
  }

  void showErrorBanner(String title, String message) {
    state = state.copyWith(
      banner: BannerState(
        type: BannerType.error,
        title: title,
        message: message,
      ),
    );
  }

  void dismissBanner() {
    state = state.copyWith(clearBanner: true);
  }

  Future<void> uploadId(String filePath) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(verificationRepositoryProvider);
      final result = await repo.uploadVerificationImage(File(filePath));
      
      state = state.copyWith(
        isLoading: false, 
        idUploaded: true, 
        currentStep: 1,
        idImageUrl: result.$1,
        idImagePublicId: result.$2,
      );
      showSuccessBanner('Successful', 'Your ID has been uploaded successfully');
    } on ApiException catch (e) {
      if (AppErrorHandler.isUnauthorized(e)) return;
      state = state.copyWith(isLoading: false);
      showErrorBanner('Upload Failed', AppErrorHandler.getUserMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false);
      showErrorBanner('Upload Failed', 'Something went wrong. Please try again.');
    }
  }

  Future<void> uploadFaceScan(String filePath) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(verificationRepositoryProvider);
      final result = await repo.uploadVerificationImage(File(filePath));
      
      state = state.copyWith(
        faceScanned: true, 
        currentStep: 2,
        selfieImageUrl: result.$1,
        selfieImagePublicId: result.$2,
      );

      // Final submission
      await submitVerification();
      
      state = state.copyWith(isLoading: false);
      showSuccessBanner('Successful', 'Your face scan has been uploaded successfully');
    } on ApiException catch (e) {
      if (AppErrorHandler.isUnauthorized(e)) return;
      state = state.copyWith(isLoading: false);
      showErrorBanner('Upload Failed', AppErrorHandler.getUserMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false);
      showErrorBanner('Upload Failed', 'Something went wrong. Please try again.');
    }
  }

  Future<void> submitVerification() async {
    if (state.idImageUrl == null || state.selfieImageUrl == null) {
      showErrorBanner('Submission Failed', 'Please upload both ID and selfie images.');
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(verificationRepositoryProvider);
      await repo.submitVerification(
        idType: state.selectedIdType?.name ?? 'id_card',
        idImageUrl: state.idImageUrl!,
        idImagePublicId: state.idImagePublicId!,
        selfieImageUrl: state.selfieImageUrl!,
        selfieImagePublicId: state.selfieImagePublicId!,
      );
      state = state.copyWith(isLoading: false);
      // Success will likely lead to navigation from the view
    } on ApiException catch (e) {
      if (AppErrorHandler.isUnauthorized(e)) return;
      state = state.copyWith(isLoading: false);
      showErrorBanner('Submission Failed', AppErrorHandler.getUserMessage(e));
    } catch (e) {
      state = state.copyWith(isLoading: false);
      showErrorBanner('Submission Failed', 'Something went wrong. Please try again.');
    }
  }

  void reset() {
    state = const VerificationState();
  }

  // Navigation
  void navigateToIdCapture(BuildContext context) {
    if (context.mounted) {
      context.pushNamed(RouteNames.idCapture);
    }
  }

  void navigateToFaceId(BuildContext context) {
    if (context.mounted) {
      context.pushNamed(RouteNames.faceIdVerification);
    }
  }

  void navigateToFaceCapture(BuildContext context) {
    if (context.mounted) {
      context.pushNamed(RouteNames.faceCapture);
    }
  }

  void navigateToVerificationComplete(BuildContext context) {
    if (context.mounted) {
      context.pushNamed(RouteNames.verificationComplete);
    }
  }

  void navigateToHome(BuildContext context) {
    if (context.mounted) {
      context.goNamed(RouteNames.home);
    }
  }
}
