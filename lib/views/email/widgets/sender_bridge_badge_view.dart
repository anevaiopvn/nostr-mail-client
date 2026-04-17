import 'package:flutter/material.dart';
import 'package:nostr_mail/nostr_mail.dart';
import 'package:nostr_mail_client/views/email/email_controller.dart';
import 'package:nostr_mail_client/widgets/nostr_avatar.dart';

class SenderBridgeBadgeView extends StatelessWidget {
  final Email email;

  const SenderBridgeBadgeView({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return NostrAvatar(
      pubkey: email.senderPubkey,
      metadata: EmailController.to.bridgeMetadata,
      radius: 12,
    );
  }
}
