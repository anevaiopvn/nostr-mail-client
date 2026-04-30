import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/inbox_controller.dart';

class OldEmailsBanner extends StatelessWidget {
  const OldEmailsBanner({
    super.key,
    required this.onDelete,
  });

  final VoidCallback onDelete;

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

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$oldCount email${oldCount == 1 ? '' : 's'} are older than 30 days',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'These emails will be permanently deleted after 30 days. You can delete them now to save space.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onErrorContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Obx(() => ElevatedButton(
              onPressed: controller.isDeletingOldEmails.value
                  ? null
                  : onDelete,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: controller.isDeletingOldEmails.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Delete now'),
            )),
          ],
        ),
      );
    });
  }
}
