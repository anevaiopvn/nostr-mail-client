import 'package:flutter/material.dart';
import 'package:nostr_mail_client/views/email/email_controller.dart';
import 'package:nostr_mail_client/widgets/nostr_avatar.dart';

class RecipientBridgeBadgeView extends StatelessWidget {
  const RecipientBridgeBadgeView({super.key});

  @override
  Widget build(BuildContext context) {
    return NostrAvatar(
      pubkey: EmailController.to.email!.recipientPubkey,
      radius: 7,
    );
  }
}
