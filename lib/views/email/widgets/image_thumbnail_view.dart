import 'package:flutter/material.dart';
import 'package:nostr_mail/nostr_mail.dart';
import 'package:nostr_mail_client/utils/get_attachements.dart';

class ImageThumbnailView extends StatelessWidget {
  final AttachmentDetails attachmentDetails;
  final Email email;

  const ImageThumbnailView({
    super.key,
    required this.attachmentDetails,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final imageData = getAttachmentData(
      mime: email.mime,
      fetchId: attachmentDetails.fetchId,
    );

    if (imageData != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.memory(
          imageData,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.broken_image,
              size: 24,
              color: Theme.of(context).colorScheme.error,
            );
          },
        ),
      );
    }

    return Icon(
      Icons.broken_image,
      size: 24,
      color: Theme.of(context).colorScheme.error,
    );
  }
}
