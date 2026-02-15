import 'package:flutter/foundation.dart';
import 'package:ndk/ndk.dart';
import 'package:sembast_cache_manager/sembast_cache_manager.dart';

import 'ndk_cache_service_io.dart'
    if (dart.library.html) 'ndk_cache_service_stub.dart'
    as io;
import 'storage_service.dart';

class NdkCacheService {
  static Future<CacheManager> createCacheManager(
    StorageService storageService,
  ) async {
    if (kIsWeb) {
      return SembastCacheManager(storageService.db);
    } else {
      return await io.createObjectBoxCacheManager();
    }
  }
}
