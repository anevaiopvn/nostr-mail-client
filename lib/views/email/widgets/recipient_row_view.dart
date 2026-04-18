import 'package:flutter/material.dart';
import 'package:nostr_mail_client/views/email/email_controller.dart';

import 'recipient_avatar_view.dart';

class RecipientRowView extends StatelessWidget {
  const RecipientRowView({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 40,
          child: Text(
            'To',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        RecipientAvatarView(),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            EmailController.to.recipientDisplayName,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
