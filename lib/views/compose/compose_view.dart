import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nostr_mail_client/views/compose/widgets/bottom_toolbar_view.dart';
import 'package:nostr_mail_client/views/compose/widgets/scrollable_content_view.dart';

import '../../controllers/compose_controller.dart';
import '../../utils/responsive_helper.dart';
import '../shared/desktop_shell.dart';

class ComposeView extends StatelessWidget {
  const ComposeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ComposeController.to;
    final isWide = ResponsiveHelper.isNotMobile(context);

    final child = SingleChildScrollView(child: ScrollableContentView());

    Widget content = Scaffold(
      appBar: AppBar(
        title: const Text('Compose'),
        actionsPadding: const EdgeInsets.only(right: 8),
        actions: [
          if (!isWide)
            Obx(
              () => controller.isSending.value
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: controller.firstSend,
                    ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: isWide
            ? Column(
                children: [
                  Expanded(child: child),
                  BottomToolbarView(),
                ],
              )
            : child,
      ),
    );

    if (isWide) {
      return DesktopShell(body: content);
    }
    return content;
  }
}
