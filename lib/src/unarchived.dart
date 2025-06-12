import 'dart:typed_data';

import 'native_types/archived_types.dart';
import 'native_types/uid.dart';
import 'plist.dart';

/// create by: YanHq
/// create time: 2025/1/16
/// des:
///

class Unarchive {
  final Uint8List archived;
  final Map<UID, dynamic> unpackedUidMap = {};
  UID topUid = UID(0);
  dynamic objects;

  Unarchive(this.archived);

  /// recursively decode the root/top object and return the result
  dynamic getTopObject() {
    unpackArchiveHeader();
    return decodeObject(topUid);
  }

  unpackArchiveHeader() {
    Map plist = Plist.loads(archived);

    if (plist.isEmpty) {
      return;
    }

    final archiver = plist['\$archiver'];
    if (archiver != 'NSKeyedArchiver') {
      throw Exception('unsupported encoder: $archiver');
    }

    final version = plist['\$version'];
    if (version != nsKeyedArchiveVersion) {
      throw Exception('expected $nsKeyedArchiveVersion, got \'$version\'');
    }

    final top = plist['\$top'];
    if (top is! Map) {
      throw Exception('no top object! plist dump: $plist');
    }

    final topUid = top['root'];
    if (topUid == null) {
      throw Exception('top object did not have a UID! dump: $top');
    }
    this.topUid = topUid;

    objects = plist['\$objects'];
    if (objects is! List) {
      throw Exception('full plist dump: $plist');
    }
  }

  dynamic decodeKey(dynamic obj, String key) {
    final value = obj[key];
    if (value is UID) {
      return decodeObject(value);
    }
    return value;
  }

  dynamic decodeObject(UID index) {
    if (index == UID.nullUID) {
      return null;
    }
    var obj = unpackedUidMap[index];
    if (identical(obj, const CycleToken())) {
      throw Exception('archive has a cycle with $index');
    }
    if (obj != null) {
      return obj;
    }
    final rawObj = objects[index.data];
    unpackedUidMap[index] = const CycleToken();
    if (rawObj is! Map) {
      unpackedUidMap[index] = obj;
      return rawObj;
    }

    final classUid = rawObj['\$class'];
    if (classUid == null) {
      throw Exception('object has no \$class: $obj');
    }

    final meta = objects[classUid.data];
    if (meta is! Map) {
      throw Exception('\$class had no metadata $index: $meta');
    }

    final name = meta['\$classname'];
    if (name is! String) {
      throw Exception('\$class had no \$classname; \$class = $meta');
    }

    final archivedObj = ArchivedObject(rawObj, this);
    obj = switch (name) {
      'NSDictionary' ||
      'NSMutableDictionary' =>
        DictArchive.decodeArchive(archivedObj),
      'NSArray' || 'NSMutableArray' => ListArchive.decodeArchive(archivedObj),
      'NSSet' || 'NSMutableSet' => SetArchive.decodeArchive(archivedObj),
      _ => throw Exception('no mapping for $name'),
    };
    unpackedUidMap[index] = obj;
    return obj;
  }
}
