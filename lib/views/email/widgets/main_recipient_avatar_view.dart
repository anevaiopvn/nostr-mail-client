import 'package:enough_mail_plus/enough_mail.dart';
import 'package:flutter/material.dart';
import 'package:nostr_mail_client/views/email/email_controller.dart';
import 'package:nostr_mail_client/widgets/email_avatar.dart';
import 'package:nostr_mail_client/widgets/nostr_avatar.dart';

class MainRecipientAvatarView extends StatelessWidget {
  const MainRecipientAvatarView({super.key});

  @override
  Widget build(BuildContext context) {
    final contactPubkey = EmailController.to.recipientContactPubkey;
    if (contactPubkey == null) {
      return EmailAvatar(
        mailAddress:
            EmailController.to.email!.mime.to?.firstOrNull ??
            MailAddress(null, ''),
        radius: 12,
      );
    }

    return NostrAvatar(
      pubkey: contactPubkey,
      metadata: EmailController.to.recipientMetadata,
      radius: 12,
    );
  }
}
