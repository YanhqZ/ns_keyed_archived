import 'dart:typed_data';

import 'package:ns_keyed_archived/src/archived.dart';
import 'package:ns_keyed_archived/src/unarchived.dart';

/// create by: YanHq
/// create time: 2025/1/16
/// des: NSKeyedArchiver
///
class NSKeyedArchiver {
  NSKeyedArchiver._();

  /// unarchive [$bytes] to object
  /// Supported types: int, double, bool, String, List, Set, Map
  static dynamic unarchive(Uint8List bytes) {
    return Unarchive(bytes).getTopObject();
  }

  /// archive [$object] to bytes
  /// Supported types: int, double, bool, String, List, Set, Map
  static Uint8List archive(Object object) {
    return Archive(input: object).toBytes();
  }
}
