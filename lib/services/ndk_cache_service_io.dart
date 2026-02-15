import 'package:flutter/foundation.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_objectbox/ndk_objectbox.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<CacheManager> createObjectBoxCacheManager() async {
  final dir = await getApplicationSupportDirectory();
  final dbName = kDebugMode ? 'ndk-obx-dev' : 'ndk-obx';
  final dbPath = p.join(dir.path, dbName);
  final cacheManager = DbObjectBox(directory: dbPath);
  await cacheManager.dbRdy;
  return cacheManager;
}
