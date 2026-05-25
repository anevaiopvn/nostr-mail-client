import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:ndk/ndk.dart';
import 'package:nostr_mail/nostr_mail.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/compose_controller.dart';
import '../../controllers/create_identity_controller.dart';
import '../../controllers/identities_controller.dart';
import '../../controllers/inbox_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../models/compose_mode.dart';
import '../../services/storage_service.dart';
import '../../views/auth/login_view.dart';
import '../../views/compose/compose_view.dart';
import '../../views/email/email_controller.dart';
import '../../views/email/email_view.dart';
import '../../views/identity/create_identity_view.dart';
import '../../views/inbox/inbox_view.dart';
import '../../views/nostr/profile_share_view.dart';
import '../../views/onboarding/onboarding_view.dart';
import '../../views/profile/profile_view.dart';
import '../../views/settings/debug_tools_view.dart';
import '../../views/settings/hosting_settings_view.dart';
import '../../views/settings/identities_view.dart';
import '../../views/settings/settings_view.dart';
import '../../views/shared/auth_shell.dart';
import '../../views/shared/not_found_view.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  /// Shared with GetX so `Get.context`, `Get.dialog`, `Get.snackbar` keep
  /// working without a `GetMaterialApp`. They all read `Get.key.currentContext`.
  static final GlobalKey<NavigatorState> _rootNavigatorKey = Get.key;
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>();

  static _AuthRefreshNotifier? _authNotifier;

  /// Must be called from `main()` *after* `AuthController` is registered.
  static GoRouter init() {
    _authNotifier ??= _AuthRefreshNotifier();
    Get.lazyPut(() => InboxController());
    return _router;
  }

  /// Global access for controllers that don't have a `BuildContext`
  /// (e.g. `AuthController` after login, `EmailController` after delete).
  /// In widgets, prefer `context.go` / `context.push`.
  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.inbox,
    refreshListenable: _authNotifier,
    redirect: _globalRedirect,
    errorBuilder: (_, _) => const NotFoundView(),
    routes: [
      // Public routes (outside shell)
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginView(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingView(),
      ),

      // Authenticated shell: holds DesktopShell (sidebar) on wide screens
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, _, child) => AuthShell(child: child),
        routes: [
          // Root path inside shell: send to inbox
          GoRoute(
            path: '/',
            redirect: (_, _) => AppRoutes.inbox,
          ),

          // Folder routes (URL drives InboxController.currentFolder)
          GoRoute(
            path: AppRoutes.inbox,
            builder: (_, _) => const InboxView(folder: MailFolder.inbox),
          ),
          GoRoute(
            path: AppRoutes.sent,
            builder: (_, _) => const InboxView(folder: MailFolder.sent),
          ),
          GoRoute(
            path: AppRoutes.archive,
            builder: (_, _) => const InboxView(folder: MailFolder.archive),
          ),
          GoRoute(
            path: AppRoutes.trash,
            builder: (_, _) => const InboxView(folder: MailFolder.trash),
          ),

          // Compose
          GoRoute(
            path: AppRoutes.compose,
            builder: (_, state) {
              final extra = state.extra is Map ? state.extra as Map : null;
              if (Get.isRegistered<ComposeController>()) {
                Get.delete<ComposeController>();
              }
              Get.put(
                ComposeController(
                  sourceEmail: extra?['email'] as Email?,
                  sourceMode: extra?['mode'] as ComposeMode?,
                ),
              );
              return const ComposeView();
            },
          ),

          // Profile
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, _) {
              Get.lazyPut(() => ProfileController());
              return const ProfileView();
            },
          ),

          // Settings tree
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, _) => const SettingsView(),
            routes: [
              GoRoute(
                path: 'identities',
                builder: (_, _) {
                  Get.lazyPut(() => IdentitiesController());
                  return const IdentitiesView();
                },
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, _) {
                      Get.lazyPut(() => CreateIdentityController());
                      return const CreateIdentityView();
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'hosting',
                builder: (_, _) => const HostingSettingsView(),
              ),
              GoRoute(
                path: 'debug-tools',
                builder: (_, _) => const DebugToolsView(),
              ),
            ],
          ),

          // Backward compat: legacy /email/:hex links
          GoRoute(
            path: AppRoutes.emailLegacy,
            redirect: (_, state) {
              final id = state.pathParameters['id'];
              if (id == null) return AppRoutes.inbox;
              return '/$id';
            },
          ),

          // Root-level NIP-19 dispatcher (handles nevent, note, npub, nprofile)
          GoRoute(
            path: '/:${AppRoutes.nostrIdParam}',
            builder: (_, state) {
              final id = state.pathParameters[AppRoutes.nostrIdParam]!;
              return _dispatchNostrId(id);
            },
          ),
        ],
      ),
    ],
  );

  static Widget _dispatchNostrId(String id) {
    if (id.startsWith('npub1') || id.startsWith('nprofile1')) {
      return ProfileShareView(bech32: id);
    }

    final hex = _toHexEventId(id);
    if (hex == null) {
      return const NotFoundView();
    }

    if (Get.isRegistered<EmailController>()) {
      Get.delete<EmailController>();
    }
    Get.put(EmailController(eventIdHex: hex));
    return const EmailView();
  }

  /// Decode bech32 (nevent/note) to hex. Pass-through if already 64-char hex.
  /// Returns null if the input is neither.
  static String? _toHexEventId(String id) {
    if (id.length == 64 && RegExp(r'^[0-9a-f]+$').hasMatch(id)) {
      return id;
    }
    if (id.startsWith('nevent1')) {
      try {
        return Nip19.decodeNevent(id).eventId;
      } catch (_) {
        return null;
      }
    }
    if (id.startsWith('note1')) {
      try {
        return Nip19.decode(id);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static String? _globalRedirect(BuildContext context, GoRouterState state) {
    final loc = state.matchedLocation;
    final storage = Get.find<StorageService>();
    final auth = Get.find<AuthController>();

    // 1. Onboarding gate
    if (!storage.hasSeenOnboarding && loc != AppRoutes.onboarding) {
      return AppRoutes.onboarding;
    }

    // 2. Guest paths: don't force auth on /login or /onboarding,
    // but kick logged-in users off /login.
    const publicPaths = {AppRoutes.login, AppRoutes.onboarding};
    if (publicPaths.contains(loc)) {
      if (auth.isLoggedIn.value && loc == AppRoutes.login) {
        return AppRoutes.inbox;
      }
      return null;
    }

    // 3. Protected paths require auth.
    if (!auth.isLoggedIn.value) {
      return AppRoutes.login;
    }

    return null;
  }
}

/// Bridges GetX's `Rx` reactivity to go_router's `refreshListenable`.
/// When `isLoggedIn` flips, the router re-evaluates its redirect so
/// auth-protected routes immediately bounce.
class _AuthRefreshNotifier extends ChangeNotifier {
  late final Worker _loginWorker;

  _AuthRefreshNotifier() {
    _loginWorker = ever(
      Get.find<AuthController>().isLoggedIn,
      (_) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _loginWorker.dispose();
    super.dispose();
  }
}
