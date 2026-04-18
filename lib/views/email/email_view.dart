import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';
import 'package:nostr_mail_client/views/email/email_controller.dart';

import '../../app/routes/app_routes.dart';
import '../../controllers/inbox_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../utils/responsive_helper.dart';
import '../shared/desktop_shell.dart';
import 'widgets/email_body_view.dart';
import 'widgets/header_view.dart';

class EmailView extends StatelessWidget {
  const EmailView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(EmailController());

    return GetBuilder<EmailController>(
      builder: (controller) {
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
            body: const Center(child: Text('Email not found')),
          );
          return isWide ? DesktopShell(body: content) : content;
        }

        Widget content = Scaffold(
          appBar: AppBar(
            title: Text(
              (controller.email!.subject?.isEmpty ?? true)
                  ? '(No subject)'
                  : controller.email!.subject!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
                      ? 'Show formatted'
                      : 'Show raw',
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
                    tooltip: 'Restore',
                    onPressed: controller.restoreEmail,
                  );
                }
                return const SizedBox.shrink();
              }),
              MenuAnchor(
                alignmentOffset: const Offset(-110, 4),
                style: MenuStyle(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        width: 2,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
                builder: (context, controller, child) {
                  return IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                  );
                },
                menuChildren: [
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.info_outline, size: 20),
                    onPressed: controller.email != null
                        ? controller.showNip59Events
                        : null,
                    child: const Text('NIP-59 Events'),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.download, size: 20),
                    onPressed: controller.downloadEmail,
                    child: const Text('Download email'),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red,
                    ),
                    onPressed: controller.deleteEmail,
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
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
                            'Sender npub: ${Nip19.encodePubKey(controller.email!.senderPubkey)}',
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
                          const Divider(height: 32),
                          EmailBodyView(email: controller.email!),
                        ],
                      ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Get.toNamed(
              AppRoutes.compose,
              arguments: {'email': controller.email, 'mode': 'reply'},
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(
              Icons.reply,
              color: Theme.of(context).colorScheme.onPrimary,
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
