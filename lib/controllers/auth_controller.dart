import 'package:get/get.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import '../services/nostr_mail_service.dart';

class AuthController extends GetxController {
  final _nostrMailService = Get.find<NostrMailService>();

  final isLoading = false.obs;
  final isLoggedIn = false.obs;
  final showMoreOptions = false.obs;
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
    // In case it wasn't called in main (testing/standalone)
    if (!isLoggedIn.value && ndk.accounts.getPublicKey() == null) {
      init();
    }
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

  Future<void> logout() async {
    isLoading.value = true;
    try {
      await _nostrMailService.logout();
      await ndkFlutter.saveAccountsState();
      isLoggedIn.value = false;
      userMetadata.value = null;
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
