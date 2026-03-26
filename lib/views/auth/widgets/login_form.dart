import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import '../../../app/routes/app_routes.dart';
import '../../../controllers/auth_controller.dart';
import '../../../utils/toast_helper.dart';

class LoginForm extends GetView<AuthController> {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
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
            enableNip07Login: false,
            enablePubkeyLogin: false,
            enableBunkerLogin: false,
            enableAmberLogin: false,
            enableAccountCreation: false,
          ),
          OutlinedButton.icon(
            onPressed: () {
              ToastHelper.error(
                context,
                'Invalid sync code',
                description:
                    "We're checking your code as you type. Once valid, you'll be signed in without having to click anything.",
              );
            },
            icon: const Icon(Icons.login),
            label: const Text('Log in'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => controller.isRegistering.value = true,
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Create an account'),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => controller.showMoreOptions.toggle(),
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
                padding: const EdgeInsets.only(top: 4),
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
                    appUrl: "https://nogringo.github.io/nostr-mail-client",
                    appImageUrl:
                        "https://raw.githubusercontent.com/nogringo/nostr-mail-client/refs/heads/main/icons/web/icon-512-maskable.png",
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
