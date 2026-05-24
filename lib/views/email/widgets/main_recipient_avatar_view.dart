import 'package:enough_mail_plus/enough_mail.dart';
import 'package:flutter/material.dart';
import 'package:nostr_mail_client/views/email/email_controller.dart';
import 'package:nostr_mail_client/widgets/email_avatar.dart';
import 'package:nostr_mail_client/widgets/nostr_avatar.dart';

class MainRecipientAvatarView extends StatelessWidget {
  const MainRecipientAvatarView({super.key});

  @override
  Widget build(BuildContext context) {
    final email = EmailController.to.email!;
    // Direct nostr conversation: the recipient pubkey IS the contact.
    if (!email.isBridged) {
      return NostrAvatar(
        pubkey: email.recipientPubkey,
        metadata: EmailController.to.recipientMetadata,
        radius: 12,
      );
    }
    // Bridged: the legacy contact lives in the MIME To header.
    return EmailAvatar(
      mailAddress: email.mime.to?.firstOrNull ?? MailAddress(null, ''),
      radius: 12,
    );
  }
}
