import 'package:flutter/material.dart';

import '../../../controllers/inbox_controller.dart';
import '../email_controller.dart';

class EmailAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const EmailAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
}

class EmailActions {
  final List<EmailAction> primary;
  final EmailAction delete;

  const EmailActions({required this.primary, required this.delete});
}

EmailActions buildEmailActions(EmailController controller, MailFolder folder) {
  final isInbox = folder == MailFolder.inbox;
  final isInArchive = folder == MailFolder.archive;
  final isInTrash = folder == MailFolder.trash;

  return EmailActions(
    primary: [
      EmailAction(
        icon: Icons.reply,
        label: 'Reply',
        onPressed: controller.replyEmail,
      ),
      if (controller.shouldShowReplyAll)
        EmailAction(
          icon: Icons.reply_all,
          label: 'Reply all',
          onPressed: controller.replyAllEmail,
        ),
      EmailAction(
        icon: Icons.forward,
        label: 'Forward',
        onPressed: controller.forwardEmail,
      ),
      if (isInArchive)
        EmailAction(
          icon: Icons.unarchive,
          label: 'Unarchive',
          onPressed: controller.unarchiveEmail,
        )
      else if (!isInTrash)
        EmailAction(
          icon: Icons.archive,
          label: 'Archive',
          onPressed: controller.archiveEmail,
        ),
      if (isInbox)
        EmailAction(
          icon: controller.isEmailRead
              ? Icons.mark_email_unread
              : Icons.mark_email_read,
          label: controller.isEmailRead ? 'Mark unread' : 'Mark read',
          onPressed: controller.toggleReadStatus,
        ),
      EmailAction(
        icon: Icons.info_outline,
        label: 'NIP-59 Events',
        onPressed: controller.showNip59Events,
      ),
      EmailAction(
        icon: Icons.repeat,
        label: 'Repost',
        onPressed: controller.repostEmail,
      ),
      EmailAction(
        icon: Icons.download,
        label: 'Download email',
        onPressed: controller.downloadEmail,
      ),
    ],
    delete: EmailAction(
      icon: Icons.delete_outline,
      label: 'Delete',
      onPressed: controller.deleteEmail,
    ),
  );
}
