import 'package:flutter/material.dart';
import 'package:nostr_mail_client/utils/format_date_time.dart';
import 'package:nostr_mail_client/views/email/email_controller.dart';
import 'package:nostr_mail_client/views/email/widgets/sender_avatar_view.dart';

import 'recipient_row_view.dart';

class HeaderView extends StatelessWidget {
  const HeaderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (EmailController.to.email!.subject?.isEmpty ?? true)
              ? '(No subject)'
              : EmailController.to.email!.subject!,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SenderAvatarView(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    EmailController.to.senderDisplayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatDateTime(EmailController.to.email!.date),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RecipientRowView(),
      ],
    );
  }
}
