import 'package:flutter/material.dart';
import 'package:nostr_mail/nostr_mail.dart';
import 'package:nostr_mail_client/utils/get_attachements.dart';
import 'package:nostr_mail_client/views/email/email_controller.dart';
import 'package:nostr_mail_client/views/email/widgets/attachment_card_view.dart';

class AttachmentsSectionView extends StatelessWidget {
  final Email email;
  final List<AttachmentDetails> attachments;

  const AttachmentsSectionView({
    super.key,
    required this.email,
    required this.attachments,
  });

  @override
  Widget build(BuildContext context) {
    final totalSize = attachments.fold<int>(
      0,
      (sum, attachment) => sum + attachment.size,
    );
    final totalSizeText = formatFileSize(totalSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Attachments',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (attachments.length > 1) ...[
              Chip(
                avatar: Icon(Icons.folder_zip),
                label: Text(totalSizeText),
                shape: StadiumBorder(),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () =>
                    EmailController.to.downloadAllAttachments(attachments),
                icon: const Icon(Icons.file_download),
                label: const Text('Download all'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: attachments
              .map(
                (attachment) =>
                    AttachmentCardView(email: email, attachment: attachment),
              )
              .toList(),
        ),
      ],
    );
  }
}
