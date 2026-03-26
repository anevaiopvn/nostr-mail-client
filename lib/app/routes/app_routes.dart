import 'package:get/get.dart';

import '../../controllers/compose_controller.dart';
import '../../controllers/inbox_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../views/auth/login_view.dart';
import '../../views/compose/compose_view.dart';
import '../../views/email/email_view.dart';
import '../../views/inbox/inbox_view.dart';
import '../../views/onboarding/onboarding_view.dart';
import '../../views/profile/profile_view.dart';
import '../../views/settings/hosting_settings_view.dart';
import '../../views/settings/settings_view.dart';
import 'middlewares/auth_middleware.dart';
import 'middlewares/guest_middleware.dart';
import 'middlewares/onboarding_middleware.dart';

class AppRoutes {
  // TODO: Implement nested routes with go_router for better desktop/web navigation.
  // This will allow DesktopShell to remain fixed while only its content (body) changes.
  static const login = '/login';
  static const inbox = '/inbox';
  static const email = '/email';
  static const compose = '/compose';
  static const profile = '/profile';
  static const settings = '/settings';
  static const onboarding = '/onboarding';
  static const nostrTechnicalSettings = '/nostr-technical-settings';

  static final routes = [
    GetPage(
      name: login,
      page: () => const LoginView(),
      middlewares: [OnboardingMiddleware(), GuestMiddleware()],
    ),
    GetPage(
      name: inbox,
      page: () => const InboxView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => InboxController());
      }),
      middlewares: [OnboardingMiddleware(), AuthMiddleware()],
    ),
    GetPage(
      name: email,
      page: () => const EmailView(),
      middlewares: [OnboardingMiddleware(), AuthMiddleware()],
    ),
    GetPage(
      name: compose,
      page: () => const ComposeView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ComposeController());
      }),
      middlewares: [OnboardingMiddleware(), AuthMiddleware()],
    ),
    GetPage(
      name: profile,
      page: () => const ProfileView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ProfileController());
      }),
      middlewares: [OnboardingMiddleware(), AuthMiddleware()],
    ),
    GetPage(
      name: settings,
      page: () => const SettingsView(),
      middlewares: [OnboardingMiddleware(), AuthMiddleware()],
    ),
    GetPage(name: onboarding, page: () => const OnboardingView()),
    GetPage(
      name: nostrTechnicalSettings,
      page: () => const HostingSettingsView(),
      middlewares: [OnboardingMiddleware(), AuthMiddleware()],
    ),
  ];
}
