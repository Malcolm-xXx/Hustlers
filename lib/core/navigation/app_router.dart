import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hustlers/features/auth/presentation/views/forgot_password_view.dart';
import 'package:hustlers/features/auth/presentation/views/reset_password_view.dart';
import 'package:hustlers/features/home/presentation/views/home_view.dart';
import 'package:hustlers/features/profile/presentation/view/profile.dart';

import '../../features/home/presentation/views/dashboard_view.dart';
import '../../features/auth/presentation/views/fingerprint_verification_view.dart';
import '../../features/auth/presentation/views/otp_verification_view.dart';
import '../../features/auth/presentation/views/role_selection_view.dart';
import '../../features/auth/presentation/views/sign_in_view.dart';
import '../../features/auth/presentation/views/sign_up_view.dart';
import '../../features/onboarding/presentation/views/onboarding_view.dart';
import '../../features/preferences/presentation/views/cooking_preference_view.dart';
import '../../features/preferences/presentation/views/primary_goal_view.dart';
import '../../features/preferences/presentation/views/set_location_view.dart';
import '../../features/splash/presentation/views/splash_view.dart';
import '../../features/verification/presentation/views/select_id_type_view.dart';
import '../../features/verification/presentation/views/id_capture_view.dart';
import '../../features/verification/presentation/views/face_id_view.dart';
import '../../features/verification/presentation/views/face_capture_verification_view.dart';
import '../../features/verification/presentation/views/verification_complete_view.dart';
import '../../features/hustle_list/presentation/views/create_hustle_list_view.dart';
import '../../features/hustle_list/presentation/views/select_location_view.dart'
    as hustle_location;
import '../../features/hustle_list/presentation/views/hustle_list_success_view.dart';
import '../../features/product/domain/entities/product_entity.dart';
import '../../features/product/presentation/views/product_detail_view.dart';
import '../../features/orders/data/models/order_model.dart';
import '../../features/orders/presentation/views/my_orders_view.dart';
import '../../features/orders/presentation/views/live_status_view.dart';
import '../../features/orders/presentation/views/rate_experience_view.dart';
import '../../features/notifications/presentation/views/notifications_view.dart';
import '../../features/seller/presentation/views/seller_dashboard_view.dart';
import '../../features/seller/presentation/views/seller_home_view.dart';
import '../../features/seller/presentation/views/seller_orders_view.dart';
import '../../features/seller/presentation/views/seller_store_view.dart';
import '../../features/seller/presentation/views/seller_insights_view.dart';
import '../../features/seller/presentation/views/add_edit_item_view.dart';
import '../../features/seller/presentation/views/seller_order_detail_view.dart';
import '../../features/seller/data/models/store_item_model.dart';
import '../../features/messaging/presentation/views/chats_list_view.dart';
import '../../features/messaging/presentation/views/chat_conversation_view.dart';
import '../../features/messaging/presentation/views/search_chat_view.dart';
import '../../features/seller/presentation/views/service_area_management_view.dart';
import '../../features/stash/presentation/views/my_stash_view.dart';
import '../../features/stash/presentation/views/checkout_view.dart';
import '../../features/stash/presentation/views/add_card_view.dart';
import '../../features/wallet/presentation/views/my_wallet_view.dart';
import '../../features/wallet/presentation/views/micro_loan_view.dart';
import '../../features/wallet/presentation/views/hustle_savings_view.dart';
import '../widgets/paystack_webview.dart';
import 'route_names.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: RoutePaths.splash,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: RoutePaths.splash,
      name: RouteNames.splash,
      builder: (context, state) => const SplashView(),
    ),
    GoRoute(
      path: RoutePaths.onboarding,
      name: RouteNames.onboarding,
      builder: (context, state) => const OnboardingView(),
    ),
    GoRoute(
      path: RoutePaths.signUp,
      name: RouteNames.signUp,
      builder: (context, state) => const SignUpView(),
    ),
    GoRoute(
      path: RoutePaths.signIn,
      name: RouteNames.signIn,
      builder: (context, state) => const SignInView(),
    ),
    GoRoute(
      path: RoutePaths.forgotPassword,
      name: RouteNames.forgotPassword,
      builder: (context, state) => const ForgotPasswordView(),
    ),
    GoRoute(
      path: RoutePaths.forgotPasswordOtp,
      name: RouteNames.forgotPasswordOtp,
      builder: (context, state) =>
          const OtpVerificationView(source: OtpSource.forgotPassword),
    ),
    GoRoute(
      path: RoutePaths.resetPassword,
      name: RouteNames.resetPassword,
      builder: (context, state) => const ResetPasswordView(),
    ),
    GoRoute(
      path: RoutePaths.otpVerification,
      name: RouteNames.otpVerification,
      builder: (context, state) => const OtpVerificationView(),
    ),
    GoRoute(
      path: RoutePaths.roleSelection,
      name: RouteNames.roleSelection,
      builder: (context, state) => const RoleSelectionView(),
    ),
    // Old auth verification routes (kept for backward compatibility)
    GoRoute(
      path: RoutePaths.idVerification,
      name: RouteNames.idVerification,
      builder: (context, state) => const SelectIdTypeView(),
    ),
    GoRoute(
      path: RoutePaths.fingerprintVerification,
      name: RouteNames.fingerprintVerification,
      builder: (context, state) => const FingerprintVerificationView(),
    ),
    GoRoute(
      path: RoutePaths.faceIdVerification,
      name: RouteNames.faceIdVerification,
      builder: (context, state) => const FaceIdView(),
    ),
    GoRoute(
      path: RoutePaths.faceCapture,
      name: RouteNames.faceCapture,
      builder: (context, state) => const FaceCaptureVerificationView(),
    ),
    // New verification routes
    GoRoute(
      path: RoutePaths.idCapture,
      name: RouteNames.idCapture,
      builder: (context, state) => const IdCaptureView(),
    ),
    GoRoute(
      path: RoutePaths.verificationComplete,
      name: RouteNames.verificationComplete,
      builder: (context, state) => const VerificationCompleteView(),
    ),
    GoRoute(
      path: RoutePaths.primaryGoal,
      name: RouteNames.primaryGoal,
      builder: (context, state) => const PrimaryGoalView(),
    ),
    GoRoute(
      path: RoutePaths.cookingPreference,
      name: RouteNames.cookingPreference,
      builder: (context, state) => const CookingPreferenceView(),
    ),
    GoRoute(
      path: RoutePaths.setLocation,
      name: RouteNames.setLocation,
      builder: (context, state) => const SetLocationView(),
    ),

    // Hustle List routes
    GoRoute(
      path: RoutePaths.createHustleList,
      name: RouteNames.createHustleList,
      builder: (context, state) => const CreateHustleListView(),
    ),
    GoRoute(
      path: RoutePaths.selectLocation,
      name: RouteNames.selectLocation,
      builder: (context, state) =>
          const hustle_location.SelectLocationView(),
    ),
    GoRoute(
      path: RoutePaths.hustleListSuccess,
      name: RouteNames.hustleListSuccess,
      builder: (context, state) => const HustleListSuccessView(),
    ),

    // Product routes
    GoRoute(
      path: RoutePaths.productDetail,
      name: RouteNames.productDetail,
      builder: (context, state) {
        final product = state.extra as ProductEntity;
        return ProductDetailView(product: product);
      },
    ),

    // Notifications
    GoRoute(
      path: RoutePaths.notifications,
      name: RouteNames.notifications,
      builder: (context, state) => const NotificationsView(),
    ),

    // Order routes (standalone, no bottom nav)
    GoRoute(
      path: RoutePaths.liveStatus,
      name: RouteNames.liveStatus,
      builder: (context, state) {
        final order = state.extra as OrderModel;
        return LiveStatusView(order: order);
      },
    ),
    GoRoute(
      path: RoutePaths.rateExperience,
      name: RouteNames.rateExperience,
      builder: (context, state) {
        final order = state.extra as OrderModel;
        return RateExperienceView(order: order);
      },
    ),

    // Seller standalone routes
    GoRoute(
      path: RoutePaths.addStoreItem,
      name: RouteNames.addStoreItem,
      builder: (context, state) => const AddEditItemView(),
    ),
    GoRoute(
      path: RoutePaths.editStoreItem,
      name: RouteNames.editStoreItem,
      builder: (context, state) {
        final item = state.extra as StoreItemModel;
        return AddEditItemView(existingItem: item);
      },
    ),
    GoRoute(
      path: RoutePaths.sellerOrderDetail,
      name: RouteNames.sellerOrderDetail,
      builder: (context, state) {
        final orderId = state.extra as String;
        return SellerOrderDetailView(orderId: orderId);
      },
    ),

    // Messaging routes
    GoRoute(
      path: RoutePaths.sellerChats,
      name: RouteNames.sellerChats,
      builder: (context, state) => const ChatsListView(),
    ),
    GoRoute(
      path: RoutePaths.chatConversation,
      name: RouteNames.chatConversation,
      builder: (context, state) {
        final chatId = state.extra as String;
        return ChatConversationView(chatId: chatId);
      },
    ),
    GoRoute(
      path: RoutePaths.searchChat,
      name: RouteNames.searchChat,
      builder: (context, state) => const SearchChatView(),
    ),

    // Stash standalone routes
    GoRoute(
      path: RoutePaths.checkout,
      name: RouteNames.checkout,
      builder: (context, state) => const CheckoutView(),
    ),
    GoRoute(
      path: RoutePaths.addCard,
      name: RouteNames.addCard,
      builder: (context, state) => const AddCardView(),
    ),

    // Payments
    GoRoute(
      path: RoutePaths.paystackWebview,
      name: RouteNames.paystackWebview,
      builder: (context, state) {
        final url = state.extra as String;
        return PaystackWebViewScreen(url: url);
      },
    ),

    // Wallet
    GoRoute(
      path: RoutePaths.wallet,
      name: RouteNames.wallet,
      builder: (context, state) => const MyWalletView(),
    ),
    GoRoute(
      path: RoutePaths.microLoan,
      name: RouteNames.microLoan,
      builder: (context, state) => const MicroLoanView(),
    ),
    GoRoute(
      path: RoutePaths.hustleSavings,
      name: RouteNames.hustleSavings,
      builder: (context, state) => const HustleSavingsView(),
    ),

    // Buyer dashboard shell
    ShellRoute(
      builder: (context, state, child) => DashboardView(child: child),
      routes: [
        GoRoute(
          path: RoutePaths.home,
          name: RouteNames.home,
          builder: (context, state) => const HomeView(),
        ),
        GoRoute(
          path: RoutePaths.stash,
          name: RouteNames.stash,
          builder: (context, state) => const MyStashView(),
        ),
        GoRoute(
          path: RoutePaths.myOrders,
          name: RouteNames.myOrders,
          builder: (context, state) => const MyOrdersView(),
        ),
        GoRoute(
          path: RoutePaths.profile,
          name: RouteNames.profile,
          builder: (context, state) => const ProfileView(),
        ),
      ],
    ),

    // Seller dashboard shell
    ShellRoute(
      builder: (context, state, child) =>
          SellerDashboardView(child: child),
      routes: [
        GoRoute(
          path: RoutePaths.sellerHome,
          name: RouteNames.sellerHome,
          builder: (context, state) => const SellerHomeView(),
        ),
        GoRoute(
          path: RoutePaths.sellerOrders,
          name: RouteNames.sellerOrders,
          builder: (context, state) => const SellerOrdersView(),
        ),
        GoRoute(
          path: RoutePaths.sellerStore,
          name: RouteNames.sellerStore,
          builder: (context, state) => const SellerStoreView(),
        ),
        GoRoute(
          path: RoutePaths.sellerInsights,
          name: RouteNames.sellerInsights,
          builder: (context, state) => const SellerInsightsView(),
        ),
      ],
    ),
  ],
);
