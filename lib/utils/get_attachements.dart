import 'dart:typed_data';

import 'package:enough_mail_plus/enough_mail.dart';
import 'package:flutter/material.dart';

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

/// Check if a file is an image based on its extension
bool isImageFile(String filename) {
  final extension = filename.split('.').last.toLowerCase();
  return [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
    'ico',
  ].contains(extension);
}

/// Check if a file is a PDF based on its extension
bool isPdfFile(String filename) {
  final extension = filename.split('.').last.toLowerCase();
  return extension == 'pdf';
}

// TODO a mime can have multiple attachments with the same filename, we should handle that case by using the fetchId instead of filename as the unique identifier for attachments

/// Get the binary data for a specific attachment
Uint8List? getAttachmentData(MimeMessage mime, String filename) {
  final contentInfos = mime.findContentInfo(
    disposition: ContentDisposition.attachment,
  );

  for (final info in contentInfos) {
    if (info.contentDisposition?.filename == filename) {
      try {
        // Get the part from fetchId
        final part = mime.getPart(info.fetchId);
        if (part != null) {
          // Decode the part data
          return part.decodeContentBinary();
        }
      } catch (e) {
        return null;
      }
    }
  }

  return null;
}

/// Get the appropriate icon for an attachment based on its file extension
IconData getAttachmentIcon(String filename) {
  final extension = filename.split('.').last.toLowerCase();

  // Images
  if ([
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
    'svg',
    'ico',
  ].contains(extension)) {
    return Icons.image;
  }

  // PDF
  if (extension == 'pdf') {
    return Icons.picture_as_pdf;
  }

  // Documents
  if (['doc', 'docx', 'txt', 'rtf', 'odt', 'pages'].contains(extension)) {
    return Icons.description;
  }

  // Spreadsheets
  if (['xls', 'xlsx', 'csv', 'ods', 'numbers'].contains(extension)) {
    return Icons.table_chart;
  }

  // Presentations
  if (['ppt', 'pptx', 'odp', 'key'].contains(extension)) {
    return Icons.slideshow;
  }

  // Archives
  if (['zip', 'rar', '7z', 'tar', 'gz', 'bz2'].contains(extension)) {
    return Icons.folder_zip;
  }

  // Audio
  if (['mp3', 'wav', 'ogg', 'flac', 'aac', 'm4a', 'wma'].contains(extension)) {
    return Icons.audio_file;
  }

  // Video
  if (['mp4', 'avi', 'mkv', 'mov', 'wmv', 'flv', 'webm'].contains(extension)) {
    return Icons.video_file;
  }

  // Code
  if ([
    'js',
    'ts',
    'py',
    'java',
    'c',
    'cpp',
    'h',
    'hpp',
    'cs',
    'php',
    'rb',
    'go',
    'rs',
    'swift',
    'kt',
    'dart',
    'html',
    'css',
    'json',
    'xml',
    'yaml',
    'yml',
  ].contains(extension)) {
    return Icons.code;
  }

  // Default attachment icon
  return Icons.attach_file;
}
