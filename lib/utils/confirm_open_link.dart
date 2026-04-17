// TODO: Add option to trust domain and skip confirmation for trusted domains (maybe at nostr level)
// TODO: Show warning when link text differs from actual URL (phishing detection)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nostr_mail_client/utils/toast_helper.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> confirmOpenLink(String url) async {
  final confirmed = await Get.dialog<bool>(
    AlertDialog(
      title: const Text('Open link?'),
      content: SelectableText(
        url,
        style: TextStyle(color: Theme.of(Get.context!).colorScheme.primary),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: url));
            Get.back(result: false);
            ToastHelper.success(Get.context!, 'Link copied');
          },
          child: const Text('Copy'),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: const Text('Open'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
