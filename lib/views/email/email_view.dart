import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:ndk/ndk.dart';
import 'package:nostr_mail_client/views/email/email_controller.dart';

import '../../app/routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/inbox_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../utils/responsive_helper.dart';
import 'widgets/desktop_actions_bar.dart';
import 'widgets/email_body_view.dart';
import 'widgets/header_view.dart';
import 'widgets/mobile_actions_bar.dart';

class EmailView extends StatelessWidget {
  const EmailView({super.key});

  /// Dynamic back navigation: pop the navigator if there's prior history
  /// (came from a folder), otherwise infer the right folder from nostr data.
  /// Cold-start at `/<event-id>` has no shell-navigator history, so we use
  /// the email's sender (== me means it's a sent email) as the hint.
  void _goBack(BuildContext context, EmailController controller) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final myPubkey = Get.find<AuthController>().publicKey;
    final isMine = controller.email?.senderPubkey == myPubkey;
    context.go(isMine ? AppRoutes.sent : AppRoutes.inbox);
  }

  @override
  Widget build(BuildContext context) {
    // EmailController is registered by the /:nostrId route builder with the
    // path-derived event id, so we just consume it here.
    return GetBuilder<EmailController>(
      builder: (controller) {
        final l = AppLocalizations.of(context);
        final isWide = ResponsiveHelper.isNotMobile(context);

        if (controller.isLoading) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (controller.email == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l.emailNotFound)),
          );
        }

        Widget content = Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => _goBack(context, controller),
            ),
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
                  onPressed: controller.toggleShowRawContent,
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
                          if (controller.isLoadingRawContent)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else
                            SelectableText(
                              controller.rawContent ?? '',
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
                            )
                          else
                            const SizedBox(height: 16),
                          EmailBodyView(email: controller.email!),
                        ],
                      ),
              ),
            ),
          ),
        );

        return content;
      },
    );
  }
}
