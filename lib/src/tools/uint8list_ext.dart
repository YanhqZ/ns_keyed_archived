import 'dart:typed_data';

/// create by: YanHq
/// create time: 2025/2/26
/// des:
///

extension NSKeyedArchivedUint8ListExt on Uint8List {
  bool startsWith(Uint8List prefix) {
    if (length < prefix.length) {
      return false;
    }

    for (int i = 0; i < prefix.length; i++) {
      if (this[i] != prefix[i]) {
        return false;
      }
    }

    return true;
  }
}
