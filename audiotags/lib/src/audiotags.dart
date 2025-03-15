import 'rust/frb_generated.dart';

import 'rust/api/api.dart' as api;
import 'rust/api/tag.dart';
import 'rust/api/error.dart';

export 'rust/api/picture.dart';
export 'rust/api/tag.dart';
export 'rust/api/error.dart';

class AudioTags {
  static bool _initialized = false;

  /// Read the metadata at the given path. Returns
  /// a [Tag] or null if there is no metadata.
  static Future<Tag?> read(String path) async {
    if (!_initialized) {
      await RustLib.init();
      _initialized = true;
    }

    try {
      return await api.read(path: path);
    } on AudioTagsError catch (e) {
      switch (e) {
        case AudioTagsError_NoTags():
          return null;
        default:
          rethrow;
      }
    }
  }

  /// Write the metadata at the given path. Previous metadata will
  /// be cleared and the metadata in [tag] will be written.
  ///
  /// Can throw a [AudioTagsError].
  static Future<void> write(String path, Tag tag) async {
    if (!_initialized) {
      await RustLib.init();
      _initialized = true;
    }

    return await api.write(path: path, data: tag);
  }
}
