import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/compose_controller.dart';
import '../../controllers/inbox_controller.dart';
import '../../views/auth/login_view.dart';
import '../../views/compose/compose_view.dart';
import '../../views/email/email_view.dart';
import '../../views/inbox/inbox_view.dart';
import '../../views/profile/profile_view.dart';
import '../../views/settings/hosting_settings_view.dart';
import '../../views/settings/settings_view.dart';

class AppRoutes {
  // TODO: Implement nested routes with go_router for better desktop/web navigation.
  // This will allow DesktopShell to remain fixed while only its content (body) changes.
  static const login = '/login';
  static const inbox = '/inbox';
  static const email = '/email';
  static const compose = '/compose';
  static const profile = '/profile';
  static const settings = '/settings';
  static const nostrTechnicalSettings = '/nostr-technical-settings';

  static final routes = [
    GetPage(
      name: login,
      page: () => const LoginView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AuthController());
      }),
    ),
    GetPage(
      name: inbox,
      page: () => const InboxView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => InboxController());
      }),
    ),
    GetPage(name: email, page: () => const EmailView()),
    GetPage(
      name: compose,
      page: () => const ComposeView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ComposeController());
      }),
    ),
    GetPage(name: profile, page: () => const ProfileView()),
    GetPage(name: settings, page: () => const SettingsView()),
    GetPage(
      name: nostrTechnicalSettings,
      page: () => const HostingSettingsView(),
    ),
  ];
}
