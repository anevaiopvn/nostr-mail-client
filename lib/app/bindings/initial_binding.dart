import 'package:get/get.dart';

import '../../services/contacts_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Services/Controllers already initialized in main():
    // - StorageService
    // - NostrMailService
    // - AuthController
    // - SettingsController (via Get.putAsync, awaited before runApp)

    Get.lazyPut(() => ContactsService());
  }
}
