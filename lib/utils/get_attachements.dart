import 'package:enough_mail_plus/enough_mail.dart';

/// Get list of attachment filenames from the email
List<String> getAttachements(MimeMessage mime) {
  final attachments = <String>[];

  // Use findContentInfo to get all attachments
  final contentInfos = mime.findContentInfo(
    disposition: ContentDisposition.attachment,
  );

  for (final info in contentInfos) {
    final filename = info.contentDisposition?.filename;
    if (filename != null && filename.isNotEmpty) {
      attachments.add(filename);
    }
  }

  return attachments;
}
