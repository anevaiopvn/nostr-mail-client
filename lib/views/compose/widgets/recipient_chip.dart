import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';

import '../../../models/recipient.dart';
import '../../../widgets/email_avatar.dart';
import '../../../widgets/nostr_avatar.dart';

class RecipientChip extends StatelessWidget {
  final Recipient recipient;
  final VoidCallback onDelete;

  const RecipientChip({
    super.key,
    required this.recipient,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (recipient.isLoading) {
      return const Chip(
        shape: StadiumBorder(),
        label: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (recipient.isNostr) {
      return _buildNostrChip(context);
    }

    return _buildLegacyChip();
  }

  Widget _buildNostrChip(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Chip(
      shape: const StadiumBorder(),
      backgroundColor: colorScheme.primaryContainer,
      side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
      avatar: _buildAvatar(context),
      label: Text(
        recipient.label,
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      deleteIcon: Icon(
        Icons.close,
        size: 18,
        color: colorScheme.primary.withValues(alpha: 0.6),
      ),
      onDeleted: onDelete,
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final pubkey = recipient.pubkey;
    if (pubkey == null) {
      return EmailAvatar(email: recipient.input, radius: 12);
    }

    return NostrAvatar(
      pubkey: pubkey,
      metadata: Metadata(
        pubKey: pubkey,
        picture: recipient.picture,
        displayName: recipient.displayName,
      ),
      radius: 12,
    );
  }

  Widget _buildLegacyChip() {
    return Chip(
      shape: const StadiumBorder(),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: Colors.grey.shade300),
      label: Text(
        recipient.label,
        style: TextStyle(color: Colors.grey.shade700),
      ),
      deleteIcon: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
      onDeleted: onDelete,
    );
  }
}
