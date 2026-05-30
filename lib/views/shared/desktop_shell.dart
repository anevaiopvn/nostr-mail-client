import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nostr_mail_client/views/shared/layouts/wide_layout.dart';

import '../../controllers/settings_controller.dart';
import '../../utils/platform_helper.dart';
import '../../utils/responsive_helper.dart';
import '../inbox/widgets/app_drawer.dart';
import 'layout_constants.dart';

class DesktopShell extends StatelessWidget {
  final Widget body;

  const DesktopShell({super.key, required this.body});

  Widget _buildBackground(BuildContext context) {
    return Obx(() {
      final image = Get.find<SettingsController>().backgroundImage.value;

      if (image != null && image.isNotEmpty) {
        // Native: local file path
        if (PlatformHelper.isNative) {
          final file = File(image);
          if (file.existsSync()) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            );
          }
        } else {
          // Web: URL
          return Image.network(
            image,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, _, _) => Container(
              color: Theme.of(context).colorScheme.tertiaryContainer,
            ),
          );
        }
      }

      return Container(color: Theme.of(context).colorScheme.tertiaryContainer);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = ResponsiveHelper.isNotMobile(context);

    final isDesktop = PlatformHelper.isDesktop;

    if (isWide) {
      Widget content = Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackground(context),
            Padding(
              padding: EdgeInsets.only(
                top: isDesktop ? LayoutConstants.windowCaptionHeight : 0,
              ),
              child: WideLayout(body: body),
            ),
          ],
        ),
      );

      return content;
    }

    // Mobile layout with drawer
    return Scaffold(
      drawer: const AppDrawer(),
      body: Stack(
        fit: StackFit.expand,
        children: [_buildBackground(context), body],
      ),
    );
  }
}
