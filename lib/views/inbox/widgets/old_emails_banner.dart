import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/inbox_controller.dart';

class OldEmailsBanner extends StatelessWidget {
  const OldEmailsBanner({super.key, required this.onDelete});

  final VoidCallback onDelete;

  Widget _buildActionButton(
    VoidCallback? onPressed,
    ColorScheme colorScheme,
    bool isDesktop,
  ) {
    final controller = Get.find<InboxController>();
    final buttonColor = colorScheme.onSurfaceVariant;

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: FilledButton(
          onPressed: onPressed,
          child: controller.isDeletingOldEmails.value
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete now'),
        ),
      );
    }

    return IconButton(
      onPressed: onPressed,
      icon: controller.isDeletingOldEmails.value
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.delete_outline, color: buttonColor),
      tooltip: 'Delete old emails',
      style: IconButton.styleFrom(foregroundColor: buttonColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InboxController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      final oldCount = controller.oldEmailsCount.value;

      // Only show in trash folder and if there are old emails
      if (controller.currentFolder.value != MailFolder.trash || oldCount == 0) {
        return const SizedBox.shrink();
      }

      final buttonEnabled = !controller.isDeletingOldEmails.value;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideBanner = constraints.maxWidth > 400;

            return Row(
              children: [
                Expanded(
                  child: Text(
                    '$oldCount old email${oldCount == 1 ? '' : 's'} to delete',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                _buildActionButton(
                  buttonEnabled ? onDelete : null,
                  colorScheme,
                  isWideBanner,
                ),
              ],
            );
          },
        ),
      );
    });
  }
}
