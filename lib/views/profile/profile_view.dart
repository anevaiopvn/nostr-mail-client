import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';

import '../../controllers/auth_controller.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/toast_helper.dart';
import '../shared/desktop_shell.dart';

// TODO: Refactor this to a GetView<ProfileController> and use a dedicated controller
// instead of StatefulWidget to maintain architectural consistency with GetX.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _pictureController = TextEditingController();
  final _aboutController = TextEditingController();

  Metadata? _currentMetadata;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _pictureController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    final pubkey = Get.find<AuthController>().publicKey;
    if (pubkey == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final ndk = Get.find<Ndk>();
      final metadata = await ndk.metadata.loadMetadata(pubkey);

      if (mounted) {
        setState(() {
          _currentMetadata = metadata;
          _nameController.text = metadata?.name ?? '';
          _displayNameController.text = metadata?.displayName ?? '';
          _pictureController.text = metadata?.picture ?? '';
          _aboutController.text = metadata?.about ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final pubkey = Get.find<AuthController>().publicKey;
    if (pubkey == null) return;

    setState(() => _isSaving = true);

    try {
      final ndk = Get.find<Ndk>();

      // Start from current object to preserve fields like banner, nip05, website, etc.
      final metadata = _currentMetadata ?? Metadata(pubKey: pubkey);

      // Update fields using setters
      metadata.name = _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim().toLowerCase().replaceAll(' ', '');
      metadata.displayName = _displayNameController.text.trim().isEmpty
          ? null
          : _displayNameController.text.trim();
      metadata.picture = _pictureController.text.trim().isEmpty
          ? null
          : _pictureController.text.trim();
      metadata.about = _aboutController.text.trim().isEmpty
          ? null
          : _aboutController.text.trim();

      metadata.updatedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await ndk.config.cache.saveMetadata(metadata);

      final event = metadata.toEvent();
      final signedEvent = await ndk.accounts.getLoggedAccount()!.signer.sign(
        event,
      );

      final broadcast = ndk.broadcast.broadcast(nostrEvent: signedEvent);
      await broadcast.broadcastDoneFuture;

      // Refresh metadata in AuthController
      Get.find<AuthController>().userMetadata.value = metadata;

      if (mounted) Get.back();
    } catch (e) {
      if (mounted) {
        ToastHelper.error(context, 'Failed to update profile');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = ResponsiveHelper.isNotMobile(context);

    Widget content = Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actionsPadding: const EdgeInsets.only(right: 8),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: ResponsiveCenter(
                maxWidth: 500,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _buildAvatarPreview(context)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        hintText: 'Your full name or alias',
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
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
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pictureController,
                      decoration: const InputDecoration(
                        labelText: 'Picture URL',
                        hintText: 'https://example.com/avatar.png',
                      ),
                      keyboardType: TextInputType.url,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _aboutController,
                      decoration: const InputDecoration(
                        labelText: 'About',
                        hintText: 'A short bio about yourself',
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
            ),
    );

    if (isWide) {
      return DesktopShell(body: content);
    }
    return content;
  }

  Widget _buildAvatarPreview(BuildContext context) {
    final pictureUrl = _pictureController.text.trim();
    final displayName = _displayNameController.text.trim();
    final name = _nameController.text.trim();
    final pubkey = Get.find<AuthController>().publicKey;
    final colorScheme = Theme.of(context).colorScheme;

    if (pictureUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage(pictureUrl),
        backgroundColor: colorScheme.primaryContainer,
        onBackgroundImageError: (e, s) {},
      );
    }

    String initial = '?';
    if (displayName.isNotEmpty) {
      initial = displayName[0].toUpperCase();
    } else if (name.isNotEmpty) {
      initial = name[0].toUpperCase();
    } else if (pubkey != null && pubkey.isNotEmpty) {
      initial = pubkey.substring(0, 2).toUpperCase();
    }

    return CircleAvatar(
      radius: 50,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
      ),
    );
  }
}
