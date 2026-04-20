import 'dart:convert';

import 'package:enough_mail_plus/enough_mail.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:ndk/ndk.dart';
import 'package:nostr_mail/nostr_mail.dart';
import 'package:nostr_mail_client/utils/toast_helper.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

import '../models/compose_attachment.dart';
import '../models/contact.dart';
import '../models/from_option.dart';
import '../models/recipient.dart';
import '../services/contacts_service.dart';
import '../services/nostr_mail_service.dart';
import '../utils/metadata_extensions.dart';
import '../utils/sender_name_helper.dart';
import 'auth_controller.dart';
import 'settings_controller.dart';

// TODO: allow attachments renaming

const String _defaultBridgeDomain = 'uid.ovh';

class ComposeController extends GetxController {
  static ComposeController get to => Get.find();

  final _nostrMailService = Get.find<NostrMailService>();
  final _contactsService = Get.find<ContactsService>();

  final isSending = false.obs;
  final recipients = <Recipient>[].obs;
  final Rxn<FromOption> selectedFrom = Rxn<FromOption>();
  final fromOptions = <FromOption>[].obs;
  final attachments = <ComposeAttachment>[].obs;

  final showExpandedFields = false.obs;
  final ccRecipients = <Recipient>[].obs;
  final bccRecipients = <Recipient>[].obs;

  late final TextEditingController toController;
  late final TextEditingController ccController;
  late final TextEditingController bccController;
  late final TextEditingController subjectController;
  late final QuillController quillController;
  final FocusNode editorFocusNode = FocusNode();
  final ScrollController editorScrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    _contactsService.loadContacts();

    final args = Get.arguments as Map<String, dynamic>?;
    final signature = Get.find<SettingsController>().currentSignature;

    toController = TextEditingController();
    ccController = TextEditingController();
    bccController = TextEditingController();
    subjectController = TextEditingController();

    // Initialize Quill controller with signature
    if (signature.isEmpty) {
      quillController = QuillController.basic();
    } else {
      final doc = Document()..insert(0, '\n\n$signature');
      quillController = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Load from options
    loadFromOptions();

    // Handle reply/forward mode
    final email = args?['email'] as Email?;
    final mode = args?['mode'] as String?;

    if (email != null && mode != null) {
      initFromEmail(email, mode);
    }
  }

  Future<bool> addRecipient(String input) =>
      _addRecipientToList(input, recipients);
  Future<bool> addCcRecipient(String input) =>
      _addRecipientToList(input, ccRecipients);
  Future<bool> addBccRecipient(String input) =>
      _addRecipientToList(input, bccRecipients);

  Future<bool> _addRecipientToList(String input, RxList<Recipient> list) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;

    // Check if already added (by input)
    if (list.any((r) => r.input == trimmed)) return false;

    // Resolve recipient first to get pubkey
    final resolved = await _resolveRecipient(trimmed);

    // Check if invalid format
    if (resolved == null) return false;

    // Check if already added (by pubkey for nostr recipients)
    if (resolved.type == RecipientType.nostr && resolved.pubkey != null) {
      if (list.any((r) => r.pubkey == resolved.pubkey)) return false;
    }

    // Add recipient
    list.add(resolved);
    return true;
  }

  void removeRecipient(int index) =>
      _removeRecipientFromList(index, recipients);
  void removeCcRecipient(int index) =>
      _removeRecipientFromList(index, ccRecipients);
  void removeBccRecipient(int index) =>
      _removeRecipientFromList(index, bccRecipients);

  void _removeRecipientFromList(int index, RxList<Recipient> list) {
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
    }
  }

  void addRecipientFromContact(Contact contact) =>
      _addContactToList(contact, recipients);
  void addCcRecipientFromContact(Contact contact) =>
      _addContactToList(contact, ccRecipients);
  void addBccRecipientFromContact(Contact contact) =>
      _addContactToList(contact, bccRecipients);

  void _addContactToList(Contact contact, RxList<Recipient> list) {
    // Check if already added (by pubkey or email)
    if (contact.pubkey != null && contact.pubkey!.isNotEmpty) {
      if (list.any((r) => r.pubkey == contact.pubkey)) return;
    } else if (contact.mailAddress?.email.isNotEmpty == true) {
      if (list.any(
        (r) =>
            r.input.toLowerCase() == contact.mailAddress!.email.toLowerCase(),
      )) {
        return;
      }
    }

    list.add(contact.toRecipient());
  }

  Set<String> get recipientIds => _getIdsFromList(recipients);
  Set<String> get ccRecipientIds => _getIdsFromList(ccRecipients);
  Set<String> get bccRecipientIds => _getIdsFromList(bccRecipients);

  /// Get all recipient identifiers for exclusion in autocomplete
  Set<String> _getIdsFromList(RxList<Recipient> list) {
    final ids = <String>{};
    for (final r in list) {
      if (r.pubkey != null) {
        ids.add(r.pubkey!);
      }
      ids.add(r.input.toLowerCase());
    }
    return ids;
  }

  /// Pick files and add them as attachments
  Future<void> pickAttachments() async {
    try {
      // TODO: limit file size
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Attachments',
        allowMultiple: true,
        withData: true, // TODO: do not work on macos
      );

      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          if (file.path != null && file.bytes != null) {
            final filename = file.name;
            final mimeType = _getMimeType(file.path!);

            attachments.add(
              ComposeAttachment(
                filename: filename,
                data: file.bytes!,
                mimeType: mimeType,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (Get.context != null) {
        ToastHelper.error(Get.context!, 'Failed to pick files: $e');
      }
    }
  }

  /// Remove attachment at the specified index
  void removeAttachment(int index) {
    if (index >= 0 && index < attachments.length) {
      attachments.removeAt(index);
    }
  }

  /// Get MIME type based on file extension
  String _getMimeType(String filePath) {
    return lookupMimeType(filePath) ?? 'application/octet-stream';
  }

  Future<Recipient?> _resolveRecipient(String input) async {
    try {
      String? pubkey;

      // Extract bech32 part (before @ if present) and decode
      final bech32Part = input.split('@').first;

      if (input.startsWith('npub1')) {
        pubkey = Nip19.decode(bech32Part);
      } else if (input.startsWith('nprofile1')) {
        pubkey = Nip19.decodeNprofile(bech32Part).pubkey;
      } else if (input.startsWith('naddr1')) {
        pubkey = Nip19.decodeNaddr(bech32Part).pubkey;
      }

      if (pubkey != null) {
        final metadata = await _fetchMetadata(pubkey);
        return Recipient(
          input: input,
          pubkey: pubkey,
          displayName: metadata?.getBestName(),
          picture: metadata?.picture,
          type: RecipientType.nostr,
        );
      }
    } catch (_) {}

    // Check if hex pubkey
    if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(input)) {
      try {
        final pubkey = input.toLowerCase();
        final metadata = await _fetchMetadata(pubkey);
        return Recipient(
          input: input,
          pubkey: pubkey,
          displayName: metadata?.getBestName(),
          picture: metadata?.picture,
          type: RecipientType.nostr,
        );
      } catch (_) {}
    }

    // Check if NIP-05
    if (input.contains('@')) {
      try {
        final pubkey = await _resolveNip05(input);
        if (pubkey != null) {
          final metadata = await _fetchMetadata(pubkey);
          return Recipient(
            input: input,
            pubkey: pubkey,
            displayName: metadata?.getBestName(),
            picture: metadata?.picture,
            type: RecipientType.nostr,
          );
        }
      } catch (_) {}
    }

    // Validate legacy email format
    if (GetUtils.isEmail(input)) {
      return Recipient(
        input: input,
        mailAddress: MailAddress(null, input),
        type: RecipientType.legacy,
      );
    }

    // Invalid format
    return null;
  }

  Future<String?> _resolveNip05(String identifier) async {
    final parts = identifier.split('@');
    if (parts.length != 2) return null;

    final name = parts[0];
    final domain = parts[1];
    final url = Uri.https(domain, '/.well-known/nostr.json', {'name': name});

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final names = json['names'] as Map<String, dynamic>?;
      if (names == null || !names.containsKey(name)) return null;

      return names[name] as String;
    } catch (_) {
      return null;
    }
  }

  Future<Metadata?> _fetchMetadata(String pubkey) async {
    try {
      return await Get.find<Ndk>().metadata.loadMetadata(pubkey);
    } catch (_) {
      return null;
    }
  }

  Future<bool> send({
    String? from,
    required String subject,
    required Document document,
  }) async {
    if (recipients.isEmpty) return false;

    isSending.value = true;
    try {
      // Convert Delta to HTML
      final converter = QuillDeltaToHtmlConverter(
        document.toDelta().toJson().cast<Map<String, dynamic>>(),
        ConverterOptions(
          converterOptions: OpConverterOptions(inlineStylesFlag: true),
        ),
      );
      final htmlBody = converter.convert();

      // Get plain text from document
      final plainText = document.toPlainText();

      // Build MIME message using MessageBuilder
      final builder = MessageBuilder.prepareMultipartAlternativeMessage();

      // Set From header
      if (from != null) {
        final displayName = selectedFrom.value?.displayName;
        builder.from = [MailAddress(displayName, from)];
      }

      // Set To recipients
      builder.to = recipients.map((r) {
        // For nostr recipients, use npub@nostr format
        // For legacy recipients, use the original input (email address)
        if (r.isNostr && r.pubkey != null) {
          final npub = Nip19.encodePubKey(r.pubkey!);
          return MailAddress(r.displayName, '$npub@nostr');
        }
        return MailAddress(r.displayName, r.input);
      }).toList();

      if (ccRecipients.isNotEmpty) {
        builder.cc = ccRecipients.map((r) {
          if (r.isNostr && r.pubkey != null) {
            final npub = Nip19.encodePubKey(r.pubkey!);
            return MailAddress(r.displayName, '$npub@nostr');
          }
          return MailAddress(r.displayName, r.input);
        }).toList();
      }

      if (bccRecipients.isNotEmpty) {
        builder.bcc = bccRecipients.map((r) {
          if (r.isNostr && r.pubkey != null) {
            final npub = Nip19.encodePubKey(r.pubkey!);
            return MailAddress(r.displayName, '$npub@nostr');
          }
          return MailAddress(r.displayName, r.input);
        }).toList();
      }

      builder.subject = subject;

      // Add body parts
      builder.addTextPlain(plainText);
      if (htmlBody.isNotEmpty) {
        builder.addTextHtml(
          htmlBody,
          transferEncoding: TransferEncoding.base64,
        );
      }

      // Add attachments if present
      for (final attachment in attachments) {
        final mediaType = MediaType.fromText(attachment.mimeType);
        builder.addBinary(
          attachment.data,
          mediaType,
          filename: attachment.filename,
        );
      }

      final message = builder.buildMimeMessage();
      await _nostrMailService.client.sendMime(message);

      return true;
    } catch (e) {
      return false;
    } finally {
      isSending.value = false;
    }
  }

  Future<String?> getDefaultFrom() async {
    try {
      final myPubkey = _nostrMailService.getPublicKey();
      if (myPubkey == null) return null;

      final emails = await _nostrMailService.client.getEmails();

      // Check sent emails first
      final sentEmail = emails
          .where((e) => e.senderPubkey == myPubkey)
          .firstOrNull;
      if (sentEmail != null && sentEmail.sender != null) {
        return sentEmail.sender!.encode();
      }

      // Fallback to received emails (use "to" which is my address)
      final receivedEmail = emails
          .where((e) => e.senderPubkey != myPubkey)
          .firstOrNull;
      if (receivedEmail != null) {
        return receivedEmail.mime.to?.firstOrNull?.encode();
      }
    } catch (_) {}

    return null;
  }

  /// Load all available From options
  Future<void> loadFromOptions() async {
    final options = <FromOption>[];
    final authController = Get.find<AuthController>();
    final npub = authController.npub;
    final metadata = authController.userMetadata.value;
    final senderName = getSenderName(metadata);

    if (npub == null) return;

    // 1. Always add npub@nostr
    options.add(
      FromOption(
        mailAddress: MailAddress(senderName, '$npub@nostr'),
        picture: metadata?.picture,
        source: FromSource.npubNostr,
      ),
    );

    // 2. Add npub@<bridge> for each configured bridge
    final settings = await _nostrMailService.client.getPrivateSettings();
    List<String> bridges = settings?.bridges ?? [];

    // Fallback to default bridge if none configured
    if (bridges.isEmpty) {
      bridges = [_defaultBridgeDomain];
    }

    for (final bridge in bridges) {
      options.add(
        FromOption(
          mailAddress: MailAddress(senderName, '$npub@$bridge'),
          picture: metadata?.picture,
          source: FromSource.npubBridge,
        ),
      );
    }

    // 3. Check if user's NIP-05 domain is a bridge
    final nip05 = metadata?.nip05;
    if (nip05 != null && nip05.contains('@')) {
      final domain = nip05.split('@').last;
      // Don't add if it's already in bridges list
      if (!bridges.contains(domain)) {
        final isBridge = await _isDomainBridge(domain);
        if (isBridge) {
          options.add(
            FromOption(
              mailAddress: MailAddress(senderName, nip05),
              picture: metadata?.picture,
              source: FromSource.nip05Bridge,
            ),
          );
        }
      }
    }

    fromOptions.value = options;

    // Set default selection
    if (selectedFrom.value == null && options.isNotEmpty) {
      await _selectDefaultFrom(options);
    }
  }

  Future<void> _selectDefaultFrom(List<FromOption> options) async {
    // Try to find last used From address
    final lastFrom = await getDefaultFrom();
    if (lastFrom != null) {
      final match = options.firstWhereOrNull((o) => o.address == lastFrom);
      if (match != null) {
        selectedFrom.value = match;
        return;
      }
    }

    // Fallback to npub@nostr
    selectedFrom.value = options.first;
  }

  /// Check if a domain is a bridge by looking up _smtp@domain
  Future<bool> _isDomainBridge(String domain) async {
    final url = Uri.https(domain, '/.well-known/nostr.json', {'name': '_smtp'});

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return false;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final names = json['names'] as Map<String, dynamic>?;

      // If _smtp exists and has a pubkey, it's a bridge
      return names != null && names.containsKey('_smtp');
    } catch (_) {
      return false;
    }
  }

  void selectFrom(FromOption option) {
    selectedFrom.value = option;
  }

  void initFromEmail(Email email, String mode) {
    final myPubkey = Get.find<NostrMailService>().getPublicKey();
    final isSentByMe = email.senderPubkey == myPubkey;
    final signature = Get.find<SettingsController>().currentSignature;
    final signatureBlock = signature.isEmpty ? '' : '\n\n$signature';

    // Get sender display for quotes
    final senderDisplay = email.sender?.encode() ?? '';

    if (mode == 'reply') {
      // Set recipient
      final replyTo = isSentByMe
          ? email.mime.to?.firstOrNull?.encode() ?? ''
          : senderDisplay;
      addRecipient(replyTo);

      // Set subject (avoid Re: Re: Re:)
      final subject = email.subject ?? '';
      subjectController.text = subject.startsWith('Re:')
          ? subject
          : 'Re: $subject';

      // Set body with quoted original message
      final dateFormat = DateFormat('EEE, MMM d, yyyy \'at\' h:mm a');
      final quotedBody = email.body
          .split('\n')
          .map((line) => '> $line')
          .join('\n');
      final bodyText =
          '$signatureBlock\n\nOn ${dateFormat.format(email.date)}, $senderDisplay wrote:\n$quotedBody';
      setQuillContent(bodyText);
    } else if (mode == 'forward') {
      // Set subject (avoid Fwd: Fwd: Fwd:)
      final subject = email.subject ?? '';
      subjectController.text = subject.startsWith('Fwd:')
          ? subject
          : 'Fwd: $subject';

      // Set body with forwarded message
      final dateFormat = DateFormat('EEE, MMM d, yyyy \'at\' h:mm a');
      final bodyText =
          '$signatureBlock\n\n---------- Forwarded message ----------\n'
          'From: $senderDisplay\n'
          'Date: ${dateFormat.format(email.date)}\n'
          'Subject: ${email.subject}\n\n'
          '${email.body}';
      setQuillContent(bodyText);
    }
  }

  void setQuillContent(String text) {
    final doc = Document()..insert(0, text);
    quillController.document = doc;
    quillController.updateSelection(
      const TextSelection.collapsed(offset: 0),
      ChangeSource.local,
    );
  }

  @override
  void dispose() {
    toController.dispose();
    ccController.dispose();
    bccController.dispose();
    subjectController.dispose();
    quillController.dispose();
    editorFocusNode.dispose();
    editorScrollController.dispose();
    super.dispose();
  }

  void toggleExpandedFields() {
    showExpandedFields.value = !showExpandedFields.value;
  }

  Future<void> handleToSubmit(String value) =>
      _handleSubmit(value, addRecipient, toController);
  Future<void> handleCcSubmit(String value) =>
      _handleSubmit(value, addCcRecipient, ccController);
  Future<void> handleBccSubmit(String value) =>
      _handleSubmit(value, addBccRecipient, bccController);

  Future<void> _handleSubmit(
    String value,
    Future<bool> Function(String) addFunc,
    TextEditingController controller,
  ) async {
    final input = value.trim();
    if (input.isNotEmpty) {
      final added = await addFunc(input);
      if (added) {
        controller.clear();
      } else {
        ToastHelper.error(Get.context!, 'Invalid recipient format');
      }
    }
  }

  Future<void> firstSend() async {
    // Try to add current input as recipient if not empty
    if (toController.text.trim().isNotEmpty) {
      await handleToSubmit(toController.text);
      // If still not empty, it was invalid and toast was already shown
      if (toController.text.trim().isNotEmpty) return;
    }
    if (ccController.text.trim().isNotEmpty) {
      await handleCcSubmit(ccController.text);
      if (ccController.text.trim().isNotEmpty) return;
    }
    if (bccController.text.trim().isNotEmpty) {
      await handleBccSubmit(bccController.text);
      if (bccController.text.trim().isNotEmpty) return;
    }

    if (recipients.isEmpty) {
      ToastHelper.error(Get.context!, 'Add at least one recipient');
      return;
    }

    final hasLegacyRecipient = recipients.any((r) => r.isLegacy);
    if (hasLegacyRecipient && selectedFrom.value == null) {
      ToastHelper.error(Get.context!, 'Select a From address for legacy email');
      return;
    }

    final success = await send(
      from: selectedFrom.value?.address,
      subject: subjectController.text,
      document: quillController.document,
    );

    if (success) {
      Get.back();
    } else {
      ToastHelper.error(Get.context!, 'Failed to send email');
    }
  }
}
