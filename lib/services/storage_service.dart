import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Stores collection images on the device's local filesystem under
/// `<app docs dir>/collections/<collectionId>.jpg`.
///
/// We deliberately avoid Firebase Storage because it requires the Blaze plan.
/// The trade-off: images are device-local — they're lost on uninstall and not
/// shared across devices. The Firestore document stores the absolute file path.
class StorageService {
  Future<Directory> _imagesDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/collections');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> saveCollectionImage({
    required String collectionId,
    required File source,
  }) async {
    final dir = await _imagesDir();
    final dest = File('${dir.path}/$collectionId.jpg');
    await source.copy(dest.path);
    return dest.path;
  }

  Future<void> deleteByPath(String path) async {
    if (path.isEmpty) return;
    try {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {
      // Best-effort cleanup; ignore failures.
    }
  }
}
