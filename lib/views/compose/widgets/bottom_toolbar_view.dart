import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nostr_mail_client/controllers/compose_controller.dart';

class BottomToolbarView extends StatelessWidget {
  const BottomToolbarView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ComposeController.to;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Obx(
            () => FilledButton(
              onPressed: controller.isSending.value
                  ? null
                  : controller.firstSend,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Visibility(
                    visible: !controller.isSending.value,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Text('Send'),
                  ),
                  Visibility(
                    visible: controller.isSending.value,
                    child: const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: controller.pickAttachments,
            icon: const Icon(Icons.attach_file),
          ),
        ],
      ),
    );
  }
}
