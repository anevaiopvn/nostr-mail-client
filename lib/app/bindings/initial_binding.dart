import 'package:get/get.dart';

import '../../controllers/settings_controller.dart';
import '../../services/contacts_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Services/Controllers already initialized in main():
    // - StorageService
    // - NostrMailService
    // - AuthController

    Get.put(SettingsController(), permanent: true);
    Get.lazyPut(() => ContactsService());
  }
}
