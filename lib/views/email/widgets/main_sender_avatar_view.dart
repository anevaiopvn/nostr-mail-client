import 'package:enough_mail_plus/enough_mail.dart';
import 'package:flutter/material.dart';
import 'package:nostr_mail/nostr_mail.dart';
import 'package:nostr_mail_client/views/email/email_controller.dart';
import 'package:nostr_mail_client/widgets/email_avatar.dart';
import 'package:nostr_mail_client/widgets/nostr_avatar.dart';

class MainSenderAvatarView extends StatelessWidget {
  final Email email;

  const MainSenderAvatarView({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final contactPubkey = EmailController.to.senderContactPubkey;
    if (contactPubkey == null) {
      return EmailAvatar(
        mailAddress: email.sender ?? MailAddress(null, ''),
        radius: 24,
      );
    }

    return NostrAvatar(
      pubkey: contactPubkey,
      metadata: EmailController.to.senderMetadata,
      radius: 24,
    );
  }
}
