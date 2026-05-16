class ApiConstants {
  ApiConstants._();

  //static const String baseUrl = 'https://hustlers-backend-zeta.vercel.app';
  static const String baseUrl = 'https://hustlers-backend-alpha.vercel.app';
  static const String apiPrefix = '/api/v1';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  static const String contentType = 'application/json';
  static const String accept = 'application/json';

  // Auth — registration & email OTP
  static const String register = '$apiPrefix/auth/register';
  static const String verifyEmailOtp = '$apiPrefix/auth/email/verify-otp';
  static const String resendEmailOtp = '$apiPrefix/auth/email/resend-otp';

  // Auth — login
  static const String login = '$apiPrefix/auth/login';
  static const String googleLogin = '$apiPrefix/auth/google';
  static const String tokenRefresh = '$apiPrefix/auth/refresh';
  static const String logout = '$apiPrefix/auth/logout';

  // Auth — me
  static const String me = '$apiPrefix/users/me';
  static const String profilePhotoUploadUrl = '$apiPrefix/users/me/profile-photo/upload-url';
  static const String profilePhotoUpdate = '$apiPrefix/users/me/profile-photo';
  static const String addresses = '$apiPrefix/users/me/addresses';
  static String addressDetails(String id) => '$apiPrefix/users/me/addresses/$id';
  static const String deviceTokens = '$apiPrefix/users/me/device-tokens';
  static String deviceTokenDetails(String id) => '$apiPrefix/users/me/device-tokens/$id';

  // Users
  static const String usersOnboard = '$apiPrefix/users/onboard';
  static const String usersMeProfileImage = '$apiPrefix/users/me/profile-image';
  static const String usersMeBannerImage = '$apiPrefix/users/me/banner-image';

  // Auth — password reset (3-step flow)
  static const String forgotPassword = '$apiPrefix/auth/password/forgot';
  static const String resendPasswordOtp = '$apiPrefix/auth/password/resend-otp';
  static const String passwordResetVerifyOtp = '$apiPrefix/auth/password/verify-otp';
  static const String resetPassword = '$apiPrefix/auth/password/reset';

  // Seller orders
  static const String sellerActiveOrders = '$apiPrefix/sellers/me/orders/active';
  static const String sellerOrderHistory = '$apiPrefix/sellers/me/orders/history';
  static String sellerOrderDetail(String id) => '$apiPrefix/sellers/me/orders/$id';
  static String orderStartShopping(String id) => '$apiPrefix/orders/$id/start-shopping';
  static String orderOnTheWay(String id) => '$apiPrefix/orders/$id/on-the-way';
  static String orderDeliver(String id) => '$apiPrefix/orders/$id/deliver';
  static String orderItemMarkGotten(String orderId, String itemId) =>
      '$apiPrefix/orders/$orderId/items/$itemId/mark-gotten';

  // Orders
  static const String orders = '$apiPrefix/orders';
  static const String ordersHistory = '$apiPrefix/orders/history';
  static const String ordersAnalytics = '$apiPrefix/orders/analytics';
  static String orderDetail(String id) => '$apiPrefix/orders/$id';
  static String orderCancel(String id) => '$apiPrefix/orders/$id/cancel';
  static String orderRate(String id) => '$apiPrefix/orders/$id/rate';
  static String orderItemCancel(String id, String itemId) =>
      '$apiPrefix/orders/$id/items/$itemId/cancel';

  // Notifications
  static const String notifications = '$apiPrefix/notifications/';
  static String notificationRead(String id) =>
      '$apiPrefix/notifications/$id/read';
  static const String notificationsReadAll = '$apiPrefix/notifications/read-all';

  // Discovery
  static const String discoveryItems = '$apiPrefix/products/';
  static const String discoverySellers = '$apiPrefix/sellers';
  static const String discoverySearch = '$apiPrefix/search/products';
  static const String discoveryLocations = '$apiPrefix/locations/';

  // Catalog
  static const String catalogCategories = '$apiPrefix/categories/';
  static const String catalogTags = '$apiPrefix/tags/';
  static const String catalogProducts = '$apiPrefix/products/';
  static String catalogProductDetails(String id) => '$apiPrefix/products/$id';



  // Verification
  static const String verificationStatus = '$apiPrefix/verification/status';
  static const String verificationSubmit = '$apiPrefix/verification/submit';
  static const String uploadPresigned = '$apiPrefix/upload/presigned';

  // Seller Analytics
  static const String sellerAnalyticsOverview = '$apiPrefix/analytics/seller/overview/';
  static const String sellerAnalyticsHotZones = '$apiPrefix/analytics/seller/hot-zones/';
  static const String sellerAnalyticsTopListings = '$apiPrefix/analytics/seller/top-listings/';
  static const String sellerAnalyticsOpportunities = '$apiPrefix/analytics/seller/service-area-opportunities/';

  // Seller Inventory
  static String sellerProducts(String id) => '$apiPrefix/catalog/sellers/$id/products/';

  // Payments
  static const String paymentsInitialize = '$apiPrefix/payments/initialize';
  static const String paymentsVerify = '$apiPrefix/payments/verify';
  static String paymentsVerifyRef(String ref) => '$apiPrefix/payments/verify/$ref';
  static const String paymentsHistory = '$apiPrefix/payments/history';
  static const String paymentCards = '$apiPrefix/payments/cards';
  static String paymentCardDetails(String id) => '$apiPrefix/payments/cards/$id';
  static String paymentCardDefault(String id) => '$apiPrefix/payments/cards/$id/default';

  // Wallet
  static const String wallet = '$apiPrefix/wallet';
  static const String walletTopup = '$apiPrefix/wallet/topup';
  static const String walletWithdraw = '$apiPrefix/wallet/withdraw';
  static const String walletWithdrawFinalize = '$apiPrefix/wallet/withdraw/finalize';
  static const String walletWithdrawResendOtp = '$apiPrefix/wallet/withdraw/resend-otp';
  static const String walletTransfer = '$apiPrefix/wallet/transfer';
  static const String walletTransferRecipient = '$apiPrefix/wallet/transfer-recipient';
  static const String walletAnalytics = '$apiPrefix/wallet/analytics';
  static const String walletTransactions = '$apiPrefix/wallet/transactions';
  static const String walletPayouts = '$apiPrefix/wallet/payouts';

  // Stash
  static const String stash = '$apiPrefix/stash';
  static const String stashSaved = '$apiPrefix/stash/saved';
  static String stashSavedDetail(String id) => '$apiPrefix/stash/saved/$id';
  static const String stashItems = '$apiPrefix/stash/items';
  static String stashItemDetail(String id) => '$apiPrefix/stash/items/$id';
  static const String stashSaveForLater = '$apiPrefix/stash/save-for-later';
  static const String stashCheckout = '$apiPrefix/stash/checkout';

  // Paystack
  static const String paystackCallbackUrl = 'https://pay.hustlers.app/callback';
}
