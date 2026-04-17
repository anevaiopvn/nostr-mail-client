import 'package:flutter/material.dart';
import 'package:nostr_mail_client/utils/get_attachements.dart';

class AttachmentChipView extends StatelessWidget {
  final AttachmentDetails? attachment;

  const AttachmentChipView({super.key, this.attachment});

  @override
  Widget build(BuildContext context) {
    String labelText = attachment?.filename ?? "";
    IconData icon = getAttachmentIcon(attachment?.filename ?? "");

    return Chip(
      avatar: Icon(icon),
      label: Text(labelText, maxLines: 1, overflow: TextOverflow.ellipsis),
      shape: const StadiumBorder(),
    );
  }
}
