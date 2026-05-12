import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';
import 'package:nostr_mail_client/views/email/email_controller.dart';

import '../../controllers/inbox_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../utils/responsive_helper.dart';
import '../shared/desktop_shell.dart';
import 'widgets/desktop_actions_bar.dart';
import 'widgets/email_body_view.dart';
import 'widgets/header_view.dart';
import 'widgets/mobile_actions_bar.dart';

class EmailView extends StatelessWidget {
  const EmailView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(EmailController());

    return GetBuilder<EmailController>(
      builder: (controller) {
        final l = AppLocalizations.of(context);
        final isWide = ResponsiveHelper.isNotMobile(context);

        if (controller.isLoading) {
          Widget content = Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
          return isWide ? DesktopShell(body: content) : content;
        }

        if (controller.email == null) {
          Widget content = Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l.emailNotFound)),
          );
          return isWide ? DesktopShell(body: content) : content;
        }

        Widget content = Scaffold(
          appBar: AppBar(
            actionsPadding: .only(right: 8),
            actions: [
              Obx(() {
                if (!Get.find<SettingsController>().showRawEmail.value) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: Icon(
                    controller.showRawContent ? Icons.article : Icons.code,
                  ),
                  tooltip: controller.showRawContent
                      ? l.emailShowFormatted
                      : l.emailShowRaw,
                  onPressed: () {
                    controller.showRawContent = !controller.showRawContent;
                    controller.update();
                  },
                );
              }),
              Obx(() {
                final isInTrash =
                    Get.find<InboxController>().currentFolder.value ==
                    MailFolder.trash;
                if (isInTrash) {
                  return IconButton(
                    icon: const Icon(Icons.restore_from_trash_outlined),
                    tooltip: l.emailRestore,
                    onPressed: controller.restoreEmail,
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
          bottomNavigationBar: !isWide ? const MobileActionsBar() : null,
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: ResponsiveCenter(
                maxWidth: 800,
                padding: const EdgeInsets.all(16),
                child: controller.showRawContent
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            l.emailSenderNpub(
                              Nip19.encodePubKey(
                                controller.email!.senderPubkey,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const Divider(height: 24),
                          SelectableText(
                            controller.email!.rawContent,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              height: 1.4,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HeaderView(),
                          // Desktop: actions bar between header and body
                          if (isWide)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              child: const DesktopActionsBar(),
                            ),
                          EmailBodyView(email: controller.email!),
                        ],
                      ),
              ),
            ),
          ),
        );

        if (isWide) {
          return DesktopShell(body: content);
        }
        return content;
      },
    );
  }
}
