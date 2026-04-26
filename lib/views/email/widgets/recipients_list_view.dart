import 'package:enough_mail_plus/enough_mail.dart';
import 'package:flutter/material.dart';
import 'package:nostr_mail_client/utils/nostr_utils.dart';
import 'package:nostr_mail_client/widgets/email_avatar.dart';
import 'package:nostr_mail_client/widgets/nostr_avatar.dart';

import '../email_controller.dart';

class RecipientsListView extends StatelessWidget {
  const RecipientsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final email = EmailController.to.email;
    if (email == null) return const SizedBox.shrink();

    final to = email.mime.to ?? [];
    final cc = email.mime.cc ?? [];
    final bcc = email.mime.bcc ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (to.isNotEmpty) ...[_buildRecipientSection(context, 'To', to)],
        if (cc.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildRecipientSection(context, 'Cc', cc),
        ],
        if (bcc.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildRecipientSection(context, 'Bcc', bcc),
        ],
      ],
    );
  }

  Widget _buildRecipientSection(
    BuildContext context,
    String label,
    List<MailAddress> recipients,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recipients
                .map((recipient) => _buildRecipientChip(context, recipient))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipientChip(BuildContext context, MailAddress recipient) {
    final emailAddress = recipient.email;

    // TODO: Add tap functionality to show actions: copy address, compose new email, add to contacts, etc.

    if (emailAddress.contains('@nostr')) {
      return _buildNostrChip(context, recipient);
    }

    return _buildLegacyChip(context, recipient);
  }

  Widget _buildNostrChip(BuildContext context, MailAddress recipient) {
    final colorScheme = Theme.of(context).colorScheme;
    final pubkey = extractPubkeyFromAddress(recipient.email);

    return Chip(
      shape: const StadiumBorder(),
      backgroundColor: colorScheme.primaryContainer,
      side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
      avatar: _buildAvatar(recipient, pubkey),
      label: Text(
        recipient.personalName ?? recipient.email,
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLegacyChip(BuildContext context, MailAddress recipient) {
    return Chip(
      shape: const StadiumBorder(),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: Colors.grey.shade300),
      label: Text(
        recipient.personalName ?? recipient.email,
        style: TextStyle(color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildAvatar(MailAddress recipient, String? pubkey) {
    if (pubkey == null) {
      return EmailAvatar(mailAddress: recipient, radius: 12);
    }

    return NostrAvatar(pubkey: pubkey, radius: 12);
  }
}
