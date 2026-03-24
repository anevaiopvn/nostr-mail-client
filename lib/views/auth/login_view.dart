import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import '../../app/routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/responsive_helper.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ResponsiveCenter(
              maxWidth: 400,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'icons/original_transparent_3x.png',
                    width: 80,
                    height: 80,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Log in to Nmail',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        NLogin(
                          ndkFlutter: controller.ndkFlutter,
                          onLoggedIn: () {
                            controller.onLoggedIn();
                            Get.offAllNamed(AppRoutes.inbox);
                          },
                          nsecLabelText: "Sync code",
                          enablePubkeyLogin: false,
                          enableBunkerLogin: false,
                          enableAccountCreation: false,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: controller.showMoreOptions.toggle,
                            icon: AnimatedRotation(
                              turns: controller.showMoreOptions.value ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.expand_more),
                            ),
                            label: const Text('More options'),
                          ),
                        ),
                        AnimatedOpacity(
                          opacity: controller.showMoreOptions.value ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: Visibility(
                            visible: controller.showMoreOptions.value,
                            maintainSize: true,
                            maintainAnimation: true,
                            maintainState: true,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: NLogin(
                                ndkFlutter: controller.ndkFlutter,
                                onLoggedIn: () {
                                  controller.onLoggedIn();
                                  Get.offAllNamed(AppRoutes.inbox);
                                },
                                enableNsecLogin: false,
                                enablePubkeyLogin: false,
                                enableAccountCreation: false,
                                nostrConnect: NostrConnect(
                                  relays: [
                                    "wss://relay.camelus.app",
                                    "wss://nostr-01.yakihonne.com",
                                  ],
                                  perms: [
                                    "get_public_key",
                                    "nip44_encrypt",
                                    "nip44_decrypt",
                                    "sign_event:5",
                                    "sign_event:13",
                                    "sign_event:1059",
                                    "sign_event:1301",
                                    "sign_event:1985",
                                  ],
                                  appName: "Nmail",
                                  appUrl:
                                      "https://nogringo.github.io/nostr-mail-client",
                                  appImageUrl:
                                      "https://raw.githubusercontent.com/nogringo/nostr-mail-client/refs/heads/main/icons/web/icon-512-maskable.png",
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
