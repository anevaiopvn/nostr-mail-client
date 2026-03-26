import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/nostr_avatar.dart';
import '../shared/desktop_shell.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = ResponsiveHelper.isNotMobile(context);

    Widget content = Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actionsPadding: const EdgeInsets.only(right: 8),
        actions: [
          GetBuilder<ProfileController>(
            builder: (controller) {
              if (controller.isLoading.value) return const SizedBox.shrink();
              return FilledButton(
                onPressed: (controller.isSaving.value || !controller.hasChanges)
                    ? null
                    : controller.saveProfile,
                child: controller.isSaving.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              );
            },
          ),
        ],
      ),
      body: GetBuilder<ProfileController>(
        builder: (controller) {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            child: ResponsiveCenter(
              maxWidth: 500,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: _buildAvatarPreview(context, controller)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: controller.displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      hintText: 'Your full name or alias',
                    ),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => controller.update(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'handle',
                      prefixText: '@',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-z0-9_.-]'),
                      ),
                    ],
                    textCapitalization: TextCapitalization.none,
                    onChanged: (_) => controller.update(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.pictureController,
                    decoration: const InputDecoration(
                      labelText: 'Picture URL',
                      hintText: 'https://example.com/avatar.png',
                    ),
                    keyboardType: TextInputType.url,
                    onChanged: (_) => controller.update(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.aboutController,
                    decoration: const InputDecoration(
                      labelText: 'About',
                      hintText: 'A short bio about yourself',
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => controller.update(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (isWide) {
      return DesktopShell(body: content);
    }
    return content;
  }

  Widget _buildAvatarPreview(BuildContext context, ProfileController controller) {
    final pictureUrl = controller.pictureController.text.trim();
    final displayName = controller.displayNameController.text.trim();
    final name = controller.nameController.text.trim();
    final pubkey = Get.find<AuthController>().publicKey;

    final previewMetadata = Metadata(
      pubKey: pubkey ?? '',
      picture: pictureUrl,
      displayName: displayName,
      name: name,
    );

    return NostrAvatar(
      pubkey: pubkey ?? '',
      metadata: previewMetadata,
      radius: 50,
    );
  }
}
