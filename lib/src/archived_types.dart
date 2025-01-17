import 'package:ns_keyed_archived/src/unarchived.dart';

import 'uid.dart';

/// create by: YanHq
/// create time: 2025/1/17
/// des:
///
///
class CycleToken {
  const CycleToken();
}

class ArchivedObject {
  final Map obj;
  final Unarchive unarchived;

  ArchivedObject(this.obj, this.unarchived);

  dynamic decodeIndex(UID index) {
    return unarchived.decodeObject(index);
  }

  decode(String key) {
    return unarchived.decodeKey(obj, key);
  }
}

/// Delegate for packing/unpacking NS(Mutable)Dictionary objects
class DictArchive {
  DictArchive._();

  static Map decodeArchive(ArchivedObject archivedObj) {
    final keyUIDs = archivedObj.decode('NS.keys');
    final valueUIDs = archivedObj.decode('NS.objects');
    final count = keyUIDs.length;
    final d = {};
    for (var i = 0; i < count; i++) {
      final key = archivedObj.decodeIndex(keyUIDs[i]);
      final value = archivedObj.decodeIndex(valueUIDs[i]);
      d[key] = value;
    }
    return d;
  }
}

/// Delegate for packing/unpacking NS(Mutable)Array objects
class ListArchive {
  ListArchive._();

  static List decodeArchive(ArchivedObject archivedObj) {
    final uidList = archivedObj.decode('NS.objects');
    return uidList.map((e) => archivedObj.decodeIndex(e)).toList();
  }
}

/// Delegate for packing/unpacking NS(Mutable)Set objects
class SetArchive {
  SetArchive._();

  static Set decodeArchive(ArchivedObject archivedObj) {
    final uidSet = archivedObj.decode('NS.objects');
    return uidSet.map((e) => archivedObj.decodeIndex(e)).toSet();
  }
}


