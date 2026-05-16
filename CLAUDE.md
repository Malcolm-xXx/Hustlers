# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
flutter run                        # Run debug
flutter build apk                  # Android release
flutter build ios                  # iOS release
flutter analyze                    # Lint
flutter test                       # All tests
flutter test test/widget_test.dart # Single test file
flutter pub get                    # Install dependencies
```

## Architecture

**Feature-first** structure under `lib/features/<feature>/`:
- `data/` — models, datasources, repositories
- `presentation/` — views, widgets, providers

Shared infrastructure lives in `lib/core/`: constants, errors, navigation, services, widgets.

### State Management — Riverpod 2.x

Uses the **Notifier** pattern (not AsyncNotifier). State classes use `copyWith`. Providers are co-located with their feature's presentation layer.

SharedPreferences is initialized before `runApp` and injected via `sharedPreferencesProvider.overrideWithValue()` in `main.dart`.

### HTTP Client — Dio + DioClient

`DioClient` (`core/services/dio_client.dart`) wraps Dio. Every HTTP method catches `DioException` and rethrows as a typed `ApiException` via `ApiErrorHandler.handle()`.

`ApiException` is a **sealed class** in `core/errors/api_exceptions.dart`. `ApiErrorHandler` checks `message`, `error`, `detail` keys on response data.

Auth token injection is stubbed but not yet active in `DioClient`.

### Routing — GoRouter

- Route names/paths: `RouteNames` / `RoutePaths` in `core/navigation/route_names.dart`
- Router config: `core/navigation/app_router.dart`
- Navigate with `context.goNamed(RouteNames.xxx)` or `context.pushNamed(...)`
- Pass objects via `state.extra` (e.g., `ProductModel`, `OrderModel`, `String` chatId)

**Two ShellRoutes (bottom nav shells):**
- **Buyer shell** (`DashboardView`): home, myOrders, profile
- **Seller shell** (`SellerDashboardView`): sellerHome, sellerOrders, sellerStore, sellerInsights

Standalone routes (no shell): all auth, verification, preferences, messaging, notifications, product detail, hustle list, order detail, live status, rate experience.

### Dual Buyer/Seller Mode

Users can switch roles. The app navigates between entirely separate route trees:
- Buyer: `/home` → buyer `DashboardView` shell
- Seller: `/seller-home` → `SellerDashboardView` shell

Role switching is done from the profile screen via `RoleSwitchBanner`.

### UI / Responsive Sizing

All dimensions use `flutter_screenutil` suffixes: `.w` (width), `.h` (height), `.sp` (font size), `.r` (radius). Never use raw pixel values.

Design tokens live in `core/constants/`:
- `AppColors` — all color constants
- `AppTextStyle` — typography presets (headingSm, bodyMd, labelMd, etc.)
- `AppAssets` — asset path strings

### Local Storage

`LocalStorageService` (`core/services/local_storage_service.dart`) provides typed accessors. Keys are in `AppConstants`.

### API Constants

Base URL and endpoints are hardcoded in `core/constants/api_constants.dart`. No environment config yet.

## Implemented Features

| Feature | Notes |
|---|---|
| splash | 2-second delay, then routes based on onboarding state |
| onboarding | 3-page swipeable, persists completion to SharedPreferences |
| auth | sign-up, sign-in, OTP, forgot password, reset password, role selection |
| verification | ID capture, face ID, fingerprint, verification complete flow |
| preferences | primary goal, cooking preference, set location |
| home (buyer) | dashboard with available items, hustlers, wallet card, search bar |
| search | filter view + search results |
| product | product detail view |
| orders (buyer) | my orders, live status, rate experience |
| seller | seller home, orders, store (add/edit items), insights, service area |
| messaging | chats list (active/resolved), chat conversation, search chat — **seller mode only, currently mock data** |
| notifications | notifications list |
| profile | buyer profile, seller profile, role-switch banner |
| hustle list | create hustle list, select location, success screen |

## Shared Widgets

`core/widgets/`: `AppPrimaryButton`, `AppTextButton`, `AppLoadingIndicator`, `AppErrorWidget`, `AppTextField`, `OtpInputField`, `AuthHeader`, `RoleSelectionCard`, `SocialLoginRow`, `InstantItemCard`.

Both button widgets support loading states, icons, and full customization.
