import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';

import '../utils/toast_helper.dart';
import 'auth_controller.dart';

class ProfileController extends GetxController {
  final nameController = TextEditingController();
  final displayNameController = TextEditingController();
  final pictureController = TextEditingController();
  final aboutController = TextEditingController();

  final Rx<Metadata?> _currentMetadata = Rx<Metadata?>(null);
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxBool isUploadingPicture = false.obs;
  final RxBool showMoreOptions = false.obs;

  bool get hasChanges {
    final metadata = _currentMetadata.value;
    if (metadata == null) return true;

    return nameController.text.trim() != (metadata.name ?? '') ||
        displayNameController.text.trim() != (metadata.displayName ?? '') ||
        pictureController.text.trim() != (metadata.picture ?? '') ||
        aboutController.text.trim() != (metadata.about ?? '');
  }

  @override
  void onInit() {
    super.onInit();
    final authController = Get.find<AuthController>();
    final metadata = authController.userMetadata.value;
    if (metadata != null) {
      _currentMetadata.value = metadata;
      nameController.text = metadata.name ?? '';
      displayNameController.text = metadata.displayName ?? '';
      pictureController.text = metadata.picture ?? '';
      aboutController.text = metadata.about ?? '';
      isLoading.value = false;
    }
    loadMetadata();
  }

  @override
  void onClose() {
    nameController.dispose();
    displayNameController.dispose();
    pictureController.dispose();
    aboutController.dispose();
    super.onClose();
  }

  Future<void> loadMetadata() async {
    final authController = Get.find<AuthController>();
    final pubkey = authController.publicKey;
    if (pubkey == null) {
      isLoading.value = false;
      return;
    }

    try {
      final ndk = Get.find<Ndk>();
      final metadata = await ndk.metadata.loadMetadata(pubkey);

      if (metadata != null) {
        authController.userMetadata.value = metadata;
        _currentMetadata.value = metadata;
        nameController.text = metadata.name ?? '';
        displayNameController.text = metadata.displayName ?? '';
        pictureController.text = metadata.picture ?? '';
        aboutController.text = metadata.about ?? '';
      }
    } catch (e) {
      ToastHelper.error(Get.context!, 'Failed to load profile data');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> pickAndUploadPicture(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select profile picture',
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) return;

    final file = result.files.single;
    isUploadingPicture.value = true;
    update();

    try {
      final ndk = Get.find<Ndk>();
      final uploadResults = await ndk.blossom.uploadBlob(
        data: file.bytes!,
        contentType: file.extension != null ? 'image/${file.extension}' : null,
      );

      final successResult = uploadResults.firstWhere(
        (r) => r.success && r.descriptor != null,
        orElse: () => uploadResults.first,
      );

      if (successResult.success && successResult.descriptor != null) {
        pictureController.text = successResult.descriptor!.url;
      } else {
        if (context.mounted) {
          ToastHelper.error(context, successResult.error ?? 'Upload failed');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ToastHelper.error(context, 'An error occurred during upload');
      }
    } finally {
      isUploadingPicture.value = false;
      update();
    }
  }

  Future<void> saveProfile() async {
    final pubkey = Get.find<AuthController>().publicKey;
    if (pubkey == null) return;

    isSaving.value = true;
    update();

    try {
      final ndk = Get.find<Ndk>();

      // Start from current object to preserve fields like banner, nip05, website, etc.
      final metadata = _currentMetadata.value ?? Metadata(pubKey: pubkey);

      // Update fields using setters
      final rawName = nameController.text.trim();
      metadata.name = rawName.isEmpty
          ? null
          : rawName.toLowerCase().replaceAll(' ', '');
      metadata.displayName = displayNameController.text.trim().isEmpty
          ? null
          : displayNameController.text.trim();
      metadata.picture = pictureController.text.trim().isEmpty
          ? null
          : pictureController.text.trim();
      metadata.about = aboutController.text.trim().isEmpty
          ? null
          : aboutController.text.trim();

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

      Get.back();
    } catch (e) {
      ToastHelper.error(Get.context!, 'Failed to update profile');
    } finally {
      isSaving.value = false;
      update();
    }
  }
}
