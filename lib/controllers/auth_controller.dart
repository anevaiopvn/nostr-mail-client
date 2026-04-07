import 'package:get/get.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import '../app/config/nostr_config.dart';
import '../app/routes/app_routes.dart';
import '../services/nostr_mail_service.dart';
import '../utils/toast_helper.dart';
import 'package:flutter/material.dart';

class AuthController extends GetxController {
  final _nostrMailService = Get.find<NostrMailService>();

  final isLoading = false.obs;
  final isLoggedIn = false.obs;
  final showMoreOptions = false.obs;
  final isRegistering = false.obs;
  final showSyncCodeExplanation = false.obs;
  final username = ''.obs;
  final usernameController = TextEditingController();
  final Rxn<Metadata> userMetadata = Rxn<Metadata>();

  Ndk get ndk => Get.find();
  NdkFlutter get ndkFlutter => Get.find();

  Future<AuthController> init() async {
    isLoading.value = true;
    try {
      await ndkFlutter.restoreAccountsState();

      if (ndk.accounts.getPublicKey() != null) {
        _nostrMailService.initClient();
        isLoggedIn.value = true;
        // Non-blocking metadata load
        loadUserMetadata();
      }
    } catch (_) {
      // Keep isLoggedIn as false
    } finally {
      isLoading.value = false;
    }
    return this;
  }

  @override
  void onInit() {
    super.onInit();
    // Sync controller with observable
    usernameController.addListener(() {
      username.value = usernameController.text;
    });
    // In case it wasn't called in main (testing/standalone)
    if (!isLoggedIn.value && ndk.accounts.getPublicKey() == null) {
      init();
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    super.onClose();
  }

  Future<void> loadUserMetadata() async {
    final pk = publicKey;
    if (pk == null) return;

    try {
      final metadata = await ndk.metadata.loadMetadata(pk);
      userMetadata.value = metadata;
    } catch (_) {}
  }

  void onLoggedIn() {
    _nostrMailService.initClient();
    isLoggedIn.value = true;
    loadUserMetadata();
  }

  Future<void> register() async {
    final isEmpty = username.value.trim().isEmpty;
    final context = Get.context;

    if (isEmpty && context != null) {
      ToastHelper.error(context, 'Please enter a username');
      return;
    }

    if (isEmpty) return;

    isLoading.value = true;

    final keyPair = Bip340.generatePrivateKey();
    ndk.accounts.loginPrivateKey(
      privkey: keyPair.privateKey!,
      pubkey: keyPair.publicKey,
    );

    await ndkFlutter.saveAccountsState();

    final rawName = username.value.trim();
    final formattedName = rawName.toLowerCase().replaceAll(' ', '');

    final metadata = Metadata(
      pubKey: keyPair.publicKey,
      name: formattedName,
      displayName: rawName,
    );

    await ndk.config.cache.saveMetadata(metadata);

    final relays = {
      for (var r in NostrConfig.recommendedInboxOutboxRelays)
        r: ReadWriteMarker.readWrite,
    };

    ndk.metadata.broadcastMetadata(metadata);
    _nostrMailService.saveNip65Relays(relays);
    _nostrMailService.saveDmRelays(NostrConfig.recommendedDmRelays);
    _nostrMailService.saveBlossomServers(NostrConfig.recommendedBlossomServers);

    onLoggedIn();

    // Clear registration state
    username.value = '';
    usernameController.clear();
    isRegistering.value = false;

    isLoading.value = false;

    // Show sync code explanation screen
    showSyncCodeExplanation.value = true;
  }

  Future<void> logout() async {
    isLoading.value = true;
    try {
      await _nostrMailService.logout();
      await ndkFlutter.saveAccountsState();

      // Reset all auth state
      isLoggedIn.value = false;
      userMetadata.value = null;
      isRegistering.value = false;
      username.value = '';
      usernameController.clear();
      showMoreOptions.value = false;

      Get.offAllNamed(AppRoutes.login);
    } finally {
      isLoading.value = false;
    }
  }

  String? get publicKey => _nostrMailService.getPublicKey();

  String? get npub {
    final pk = publicKey;
    if (pk == null) return null;
    return Nip19.encodePubKey(pk);
  }

  String? getNsec() {
    final account = ndk.accounts.getLoggedAccount();
    if (account == null || account.type != AccountType.privateKey) return null;

    final signer = account.signer as Bip340EventSigner;
    if (signer.privateKey == null) return null;

    return Nip19.encodePrivateKey(signer.privateKey!);
  }
}
