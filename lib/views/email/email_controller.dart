import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';
import 'package:nostr_mail/nostr_mail.dart';
import 'package:nostr_mail_client/app/routes/app_routes.dart';
import 'package:nostr_mail_client/controllers/inbox_controller.dart';
import 'package:nostr_mail_client/models/compose_mode.dart';
import 'package:nostr_mail_client/controllers/settings_controller.dart';
import 'package:nostr_mail_client/services/nostr_mail_service.dart';
import 'package:nostr_mail_client/utils/get_attachements.dart';
import 'package:nostr_mail_client/utils/get_mime_type.dart';
import 'package:nostr_mail_client/utils/metadata_extensions.dart';
import 'package:nostr_mail_client/utils/nostr_utils.dart';
import 'package:nostr_mail_client/utils/toast_helper.dart';
import 'package:nostr_mail_client/views/email/widgets/nip59_events_dialog.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';
import 'package:nostr_mail_client/services/android_file_saver.dart';
import 'package:nostr_mail_client/utils/platform_helper.dart';

import '../../l10n/generated/app_localizations.dart';

class EmailController extends GetxController {
  static EmailController get to => Get.find();

  Email? email;
  Metadata? senderMetadata;
  Metadata? bridgeMetadata; // Bridge for sender
  Metadata? recipientMetadata;
  Metadata? recipientBridgeMetadata; // Bridge for recipient
  bool isLoading = true;
  bool showRawContent = false;
  bool showRecipients = false;
  late bool showImages;

  EmailController() {
    showImages = Get.find<SettingsController>().alwaysLoadImages.value;
    loadEmail();
  }

  /// Get contact pubkey for sender (from address)
  String? get senderContactPubkey {
    if (email == null) return null;
    final senderAddress = email!.sender?.email;
    return senderAddress != null
        ? extractPubkeyFromAddress(senderAddress)
        : null;
  }

  /// Get contact pubkey for recipient (to address)
  String? get recipientContactPubkey {
    if (email == null) return null;
    final toAddress = email!.mime.to?.firstOrNull?.email;
    return toAddress != null ? extractPubkeyFromAddress(toAddress) : null;
  }

  /// Check if sender has a bridge (for received emails)
  bool get senderHasBridge => email?.isBridged ?? false;

  /// Check if recipient has a bridge (for sent emails)
  bool get recipientHasBridge => email?.isBridged ?? false;

  String get senderDisplayName {
    // Always show the from address/name
    return senderMetadata?.getBestName() ?? email!.sender?.encode() ?? '';
  }

  String get recipientDisplayName {
    if (recipientMetadata != null) {
      return recipientMetadata!.getBestName();
    }
    final pubkey = recipientContactPubkey ?? email?.recipientPubkey;
    if (pubkey != null && pubkey.isNotEmpty) {
      return getAnonName(pubkey);
    }
    return email!.mime.to?.firstOrNull?.encode() ?? '';
  }

  /// Check if Reply All should be shown (multiple recipients or cc/bcc)
  bool get shouldShowReplyAll {
    if (email == null) return false;

    final to = email!.mime.to ?? [];
    final cc = email!.mime.cc ?? [];
    final bcc = email!.mime.bcc ?? [];

    // Show Reply All if:
    // - More than 1 "to" recipient
    // - OR there are cc recipients
    // - OR there are bcc recipients
    return to.length > 1 || cc.isNotEmpty || bcc.isNotEmpty;
  }

  /// Check if current email is read
  bool get isEmailRead {
    if (email == null) return true;
    return Get.find<InboxController>().isEmailRead(email!.id);
  }

  /// Toggle email read/unread status
  void toggleReadStatus() async {
    if (email == null) return;

    final inboxController = Get.find<InboxController>();
    if (isEmailRead) {
      await inboxController.markAsUnread(email!.id);
    } else {
      await inboxController.markAsRead(email!.id);
    }
    update();
  }

  Future<void> loadEmail() async {
    final emailId = Get.parameters['id'];
    if (emailId == null) {
      Get.back();
      return;
    }

    final nostrMailService = Get.find<NostrMailService>();
    final loaded = await nostrMailService.client.getEmail(emailId);

    if (loaded != null) {
      loadSenderMetadata(loaded);
      loadRecipientMetadata(loaded);
    }

    email = loaded;
    isLoading = false;
    update();

    // Auto-mark as read for inbox emails only (non-blocking)
    if (loaded != null) {
      final inboxController = Get.find<InboxController>();
      if (inboxController.currentFolder.value == MailFolder.inbox) {
        // Non-blocking: mark as read without awaiting
        inboxController.markAsRead(loaded.id);
      }
    }
  }

  Future<void> loadSenderMetadata(Email loadedEmail) async {
    try {
      final ndk = Get.find<Ndk>();
      final senderAddress = loadedEmail.sender?.email;
      final contactPubkey = senderAddress != null
          ? extractPubkeyFromAddress(senderAddress)
          : null;

      // Always load senderPubkey metadata (the actual Nostr sender)
      final senderMeta = await ndk.metadata.loadMetadata(
        loadedEmail.senderPubkey,
      );
      if (senderMeta != null) {
        if (loadedEmail.isBridged) {
          bridgeMetadata = senderMeta;
        } else {
          senderMetadata = senderMeta;
        }
        update();
      }

      // If bridged and we can extract contact pubkey, load it too
      if (loadedEmail.isBridged && contactPubkey != null) {
        final contactMeta = await ndk.metadata.loadMetadata(contactPubkey);
        if (contactMeta != null) {
          senderMetadata = contactMeta;
          update();
        }
      }
    } catch (_) {}
  }

  Future<void> loadRecipientMetadata(Email loadedEmail) async {
    try {
      final ndk = Get.find<Ndk>();
      final toAddress = loadedEmail.mime.to?.firstOrNull?.email;
      final contactPubkey = toAddress != null
          ? extractPubkeyFromAddress(toAddress)
          : null;

      // Always load recipientPubkey metadata (the actual Nostr recipient)
      final recipientMeta = await ndk.metadata.loadMetadata(
        loadedEmail.recipientPubkey,
      );
      if (recipientMeta != null) {
        if (loadedEmail.isBridged) {
          recipientBridgeMetadata = recipientMeta;
        } else {
          recipientMetadata = recipientMeta;
        }
        update();
      }

      // If bridged and we can extract contact pubkey, load it too
      if (loadedEmail.isBridged && contactPubkey != null) {
        final contactMeta = await ndk.metadata.loadMetadata(contactPubkey);
        if (contactMeta != null) {
          recipientMetadata = contactMeta;
          update();
        }
      }
    } catch (_) {}
  }

  Future<void> deleteEmail() async {
    if (email == null) return;

    final l = AppLocalizations.of(Get.context!);
    final inboxController = Get.find<InboxController>();
    final isInTrash = inboxController.currentFolder.value == MailFolder.trash;

    if (isInTrash) {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: Text(l.emailDeletePermanentlyTitle),
          content: Text(l.emailDeletePermanentlyMessage),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text(l.actionCancel),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l.actionDelete),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await inboxController.deleteEmail(email!.id);
    } else {
      inboxController.deleteEmail(email!.id);
    }
    Get.back();
  }

  Future<void> showNip59Events() async {
    if (email == null) return;

    final nostrMailService = Get.find<NostrMailService>();

    final giftWrap = await nostrMailService.client.getGiftWrap(email!.id);
    final seal = await nostrMailService.client.getSeal(email!.id);
    final rumor = await nostrMailService.client.getRumor(email!.id);

    await showNip59EventsDialog(
      context: Get.context!,
      giftWrap: giftWrap,
      seal: seal,
      rumor: rumor,
    );
  }

  void restoreEmail() {
    if (email == null) return;

    Get.find<InboxController>().restoreFromTrash(email!.id);
    Get.back();
  }

  void handleAttachmentTap({
    required AttachmentDetails attachmentDetails,
    bool isImage = false,
    bool isPdf = false,
  }) {
    if (isImage) {
      showImageViewer(attachmentDetails: attachmentDetails);
    } else if (isPdf) {
      showPdfViewer(attachmentDetails: attachmentDetails);
    } else {
      downloadAttachment(attachmentDetails: attachmentDetails);
    }
  }

  Future<void> downloadEmail() async {
    if (email == null) return;

    final l = AppLocalizations.of(Get.context!);
    try {
      final subject = (email!.subject?.isEmpty ?? true)
          ? l.emailDefaultFilename
          : email!.subject!;
      final fileName = subject.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

      final bytes = utf8.encode(email!.rawContent);

      String result;
      if (PlatformHelper.isAndroid) {
        result = await AndroidFileSaver.saveToDownloads(
          fileName: '$fileName.eml',
          bytes: Uint8List.fromList(bytes),
          mimeType: 'message/rfc822',
        );
      } else {
        result = await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(bytes),
          fileExtension: 'eml',
          mimeType: MimeType.other,
        );
      }

      ToastHelper.success(Get.context!, l.emailSaved(result));
    } catch (e) {
      ToastHelper.error(Get.context!, l.emailSaveFailed(e.toString()));
    }
  }

  Future<void> repostEmail() async {
    if (email == null) return;

    final l = AppLocalizations.of(Get.context!);
    try {
      final nostrMailService = Get.find<NostrMailService>();
      final rumor = await nostrMailService.client.getRumor(email!.id);

      if (rumor == null) {
        ToastHelper.error(Get.context!, l.emailRepostFailedEvent);
        return;
      }

      await nostrMailService.client.repost(rumor);
      ToastHelper.success(Get.context!, l.emailRepostSuccess);
    } catch (e) {
      ToastHelper.error(Get.context!, l.emailRepostFailed(e.toString()));
    }
  }

  void replyEmail() {
    if (email == null) return;
    Get.toNamed(
      AppRoutes.compose,
      arguments: {'email': email, 'mode': ComposeMode.reply},
    );
  }

  void replyAllEmail() {
    if (email == null) return;
    Get.toNamed(
      AppRoutes.compose,
      arguments: {'email': email, 'mode': ComposeMode.replyAll},
    );
  }

  void forwardEmail() {
    if (email == null) return;
    Get.toNamed(
      AppRoutes.compose,
      arguments: {'email': email, 'mode': ComposeMode.forward},
    );
  }

  void archiveEmail() {
    if (email == null) return;
    Get.find<InboxController>().moveToArchive(email!.id);
    Get.back();
  }

  void unarchiveEmail() {
    if (email == null) return;
    Get.find<InboxController>().restoreFromArchive(email!.id);
    Get.back();
  }

  Future<void> downloadAttachment({
    required AttachmentDetails attachmentDetails,
  }) async {
    final l = AppLocalizations.of(Get.context!);
    final fileData = getAttachmentData(
      mime: email!.mime,
      fetchId: attachmentDetails.fetchId,
    );
    if (fileData == null) {
      ToastHelper.error(Get.context!, l.emailAttachmentLoadFailed);
      return;
    }

    try {
      // Extract file extension
      final extension = p
          .extension(attachmentDetails.filename)
          .toLowerCase()
          .replaceFirst('.', '');

      // Map common extensions to MIME types
      MimeType mimeType = getMimeType(extension);

      // Clean filename (remove path if any)
      final cleanName = p.basename(attachmentDetails.filename);

      String result;
      if (PlatformHelper.isAndroid) {
        result = await AndroidFileSaver.saveToDownloads(
          fileName: cleanName,
          bytes: fileData,
          mimeType: _getMimeTypeString(mimeType, extension),
        );
      } else {
        result = await FileSaver.instance.saveFile(
          name: p.basenameWithoutExtension(cleanName),
          bytes: fileData,
          fileExtension: extension,
          mimeType: mimeType,
        );
      }

      ToastHelper.success(Get.context!, l.emailFileSaved(result));
    } catch (e) {
      ToastHelper.error(Get.context!, l.emailFileSaveFailed(e.toString()));
    }
  }

  Future<void> downloadAllAttachments(
    List<AttachmentDetails> attachments,
  ) async {
    final l = AppLocalizations.of(Get.context!);
    int successCount = 0;
    int failureCount = 0;

    for (final attachment in attachments) {
      final fileData = getAttachmentData(
        mime: email!.mime,
        fetchId: attachment.fetchId,
      );
      if (fileData == null) {
        failureCount++;
        continue;
      }

      try {
        // Extract file extension
        final extension = p
            .extension(attachment.filename)
            .toLowerCase()
            .replaceFirst('.', '');

        // Map common extensions to MIME types
        MimeType mimeType = getMimeType(extension);

        // Clean filename (remove path if any)
        final cleanName = p.basename(attachment.filename);

        if (PlatformHelper.isAndroid) {
          await AndroidFileSaver.saveToDownloads(
            fileName: cleanName,
            bytes: fileData,
            mimeType: _getMimeTypeString(mimeType, extension),
          );
        } else {
          await FileSaver.instance.saveFile(
            name: p.basenameWithoutExtension(cleanName),
            bytes: fileData,
            fileExtension: extension,
            mimeType: mimeType,
          );
        }
        successCount++;
      } catch (e) {
        failureCount++;
      }
    }

    if (failureCount == 0) {
      ToastHelper.success(
        Get.context!,
        l.emailDownloadedAllSuccess(successCount),
      );
    } else if (successCount == 0) {
      ToastHelper.error(Get.context!, l.emailDownloadedAllFailed(failureCount));
    } else {
      ToastHelper.info(
        Get.context!,
        l.emailDownloadedMixed(successCount, failureCount),
      );
    }
  }

  void showImageViewer({required AttachmentDetails attachmentDetails}) {
    final l = AppLocalizations.of(Get.context!);
    final imageData = getAttachmentData(
      mime: email!.mime,
      fetchId: attachmentDetails.fetchId,
    );
    if (imageData != null) {
      Navigator.of(Get.context!).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                attachmentDetails.filename,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: () =>
                      downloadAttachment(attachmentDetails: attachmentDetails),
                  tooltip: l.emailDownload,
                ),
              ],
            ),
            body: Center(
              child: InteractiveViewer(
                child: Image.memory(imageData, fit: BoxFit.contain),
              ),
            ),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      ToastHelper.error(Get.context!, l.emailImageLoadFailed);
    }
  }

  void showPdfViewer({required AttachmentDetails attachmentDetails}) {
    final l = AppLocalizations.of(Get.context!);
    final pdfData = getAttachmentData(
      mime: email!.mime,
      fetchId: attachmentDetails.fetchId,
    );
    if (pdfData != null) {
      Navigator.of(Get.context!).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(
                attachmentDetails.filename,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () =>
                      downloadAttachment(attachmentDetails: attachmentDetails),
                  tooltip: l.emailDownload,
                ),
              ],
            ),
            body: PdfViewer.data(
              pdfData,
              sourceName: attachmentDetails.filename,
            ),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      ToastHelper.error(Get.context!, l.emailPdfLoadFailed);
    }
  }

  String _getMimeTypeString(MimeType mimeType, String extension) {
    switch (mimeType) {
      case MimeType.pdf:
        return 'application/pdf';
      case MimeType.jpeg:
        return 'image/jpeg';
      case MimeType.png:
        return 'image/png';
      case MimeType.gif:
        return 'image/gif';
      case MimeType.webp:
        return 'image/webp';
      case MimeType.text:
        return 'text/plain';
      case MimeType.xml:
        return 'text/xml';
      case MimeType.json:
        return 'application/json';
      case MimeType.zip:
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }
}
