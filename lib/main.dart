import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/ndk_flutter.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart' as ndk_flutter;
import 'package:nostr_mail_client/utils/responsive_helper.dart';
import 'package:system_theme/system_theme.dart';
import 'package:toastification/toastification.dart';
import 'package:window_manager/window_manager.dart';

import 'app/bindings/initial_binding.dart';
import 'app/config/nostr_config.dart';
import 'app/routes/app_routes.dart';
import 'controllers/auth_controller.dart';
import 'controllers/settings_controller.dart';
import 'services/ndk_cache_service.dart';
import 'services/nostr_mail_service.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';
import 'utils/event_verifiers.dart';
import 'utils/platform_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager for desktop
  if (PlatformHelper.isDesktop) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(titleBarStyle: TitleBarStyle.hidden);
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Initialize system theme
  await SystemTheme.accentColor.load();

  // Initialize storage service
  final storageService = StorageService();
  await storageService.init();
  Get.put(storageService, permanent: true);

  // Initialize NDK with switchable verifier for hot-swap capability
  final cacheManager = await NdkCacheService.createCacheManager(storageService);
  final skipVerification =
      await storageService.getSetting<bool>(
        SettingsController.skipEventVerificationKey,
      ) ??
      false;
  final defaultVerifier = kIsWeb ? WebEventVerifier() : RustEventVerifier();
  final switchableVerifier = SwitchableVerifier(
    skipVerification ? NoVerifier() : defaultVerifier,
  );
  Get.put(switchableVerifier, permanent: true);
  final ndk = Ndk(
    NdkConfig(
      eventVerifier: switchableVerifier,
      cache: cacheManager,
      bootstrapRelays: NostrConfig.bootstrapRelays,
      fetchedRangesEnabled: true,
    ),
  );
  Get.put(ndk, permanent: true);
  final ndkFlutter = NdkFlutter(ndk: ndk);
  Get.put(ndkFlutter, permanent: true);

  // Initialize Services and Controllers early for Middlewares
  Get.put(NostrMailService(), permanent: true);
  final authController = AuthController();
  await authController.init();
  Get.put(authController, permanent: true);

  // Initialize theme service
  await Get.putAsync(() => ThemeService().init(), permanent: true);

  // Load theme mode before app starts
  final themeModeIndex =
      await storageService.getSetting<int>(SettingsController.themeModeKey) ??
      0;
  final initialThemeMode = ThemeMode.values[themeModeIndex];

  runApp(MainApp(initialThemeMode: initialThemeMode));
}

class MainApp extends StatelessWidget {
  final ThemeMode initialThemeMode;

  const MainApp({super.key, required this.initialThemeMode});

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();

    return Obx(() {
      final systemAccent = SystemTheme.accentColor.accent;

      final lightScheme =
          themeService.lightColorScheme.value ??
          ColorScheme.fromSeed(seedColor: systemAccent);
      final darkScheme =
          themeService.darkColorScheme.value ??
          ColorScheme.fromSeed(
            seedColor: systemAccent,
            brightness: Brightness.dark,
          );

      return ToastificationWrapper(
        child: GetMaterialApp(
          title: 'Nmail',
          // TODO: Extract repetitive InputDecorationTheme to a shared variable
          theme: ThemeData.from(colorScheme: lightScheme).copyWith(
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          darkTheme: ThemeData.from(colorScheme: darkScheme).copyWith(
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          themeMode: initialThemeMode,
          locale: const Locale('en'),
          localizationsDelegates: [
            ndk_flutter.AppLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          initialBinding: InitialBinding(),
          getPages: AppRoutes.routes,
          defaultTransition: GetPlatform.isMobile
              ? null
              : Transition.noTransition,
          initialRoute: AppRoutes.inbox,
          builder: (context, child) {
            if (PlatformHelper.isDesktop) {
              return DragToResizeArea(
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surface,
                  child: Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          top: ResponsiveHelper.isMobile(context) ? 32 : 0,
                        ),
                        child: child!,
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 32,
                        child: Row(
                          children: [
                            Expanded(child: DragToMoveArea(child: Container())),
                            SizedBox(
                              width: 154,
                              child: WindowCaption(
                                brightness: Theme.of(context).brightness,
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      NPendingRequests(ndkFlutter: Get.find()),
                    ],
                  ),
                ),
              );
            }
            return Stack(
              children: [
                child!,
                NPendingRequests(ndkFlutter: Get.find()),
              ],
            );
          },
        ),
      );
    });
  }
}
