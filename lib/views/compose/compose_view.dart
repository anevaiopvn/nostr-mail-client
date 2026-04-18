import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:nostr_mail_client/views/compose/widgets/attachment_chip.dart';
import 'package:nostr_mail_client/views/compose/widgets/from_selector_view.dart';
import 'package:nostr_mail_client/views/compose/widgets/quill_toolbar_view.dart';

import '../../controllers/compose_controller.dart';
import '../../utils/responsive_helper.dart';
import '../shared/desktop_shell.dart';
import 'widgets/recipient_autocomplete.dart';
import 'widgets/recipient_chip.dart';

class ComposeView extends StatelessWidget {
  const ComposeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ComposeController.to;
    final isWide = ResponsiveHelper.isNotMobile(context);

    Widget content = Scaffold(
      appBar: AppBar(
        title: const Text('Compose'),
        actionsPadding: const EdgeInsets.only(right: 8),
        actions: [
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                FromSelectorView(),
                const Divider(height: 1),
                Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (controller.recipients.isNotEmpty)
                        SizedBox(
                          height: 48,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            itemCount: controller.recipients.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) => RecipientChip(
                              recipient: controller.recipients[index],
                              onDelete: () => controller.removeRecipient(index),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: RecipientAutocomplete(
                          textController: controller.toController,
                          hintText: controller.recipients.isEmpty
                              ? 'To'
                              : 'Add more',
                          excludeIds: controller.recipientIds,
                          onContactSelected: (contact) {
                            controller.addRecipientFromContact(contact);
                          },
                          onManualInput: (input) async {
                            return await controller.addRecipient(input);
                          },
                          onSubmitted: controller.handleToSubmit,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: TextField(
                    controller: controller.subjectController,
                    decoration: InputDecoration(
                      hintText: 'Subject',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        onPressed: controller.pickAttachments,
                        icon: Icon(Icons.attach_file),
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const Divider(height: 1),
                QuillToolbarView(),
                const Divider(height: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: QuillEditor(
                      controller: controller.quillController,
                      focusNode: controller.editorFocusNode,
                      scrollController: controller.editorScrollController,
                      config: QuillEditorConfig(
                        placeholder: 'Compose email',
                        expands: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ),

                Obx(() {
                  if (controller.attachments.isEmpty) return Container();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (
                              int i = 0;
                              i < controller.attachments.length;
                              i++
                            )
                              AttachmentChip(
                                attachment: controller.attachments[i],
                                onDelete: () => controller.removeAttachment(i),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
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
  }
}
