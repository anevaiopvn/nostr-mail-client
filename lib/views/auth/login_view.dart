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
                    'Nostr Mail',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Email over Nostr',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  NLogin(
                    ndkFlutter: controller.ndkFlutter,
                    onLoggedIn: () {
                      controller.onLoggedIn();
                      Get.offAllNamed(AppRoutes.inbox);
                    },
                    enableNpubLogin: false,
                    enableNip05Login: false,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
