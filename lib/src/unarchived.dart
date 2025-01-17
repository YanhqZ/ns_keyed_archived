import 'dart:io';
import 'dart:typed_data';

import 'plist.dart';
import 'archived_types.dart';
import 'uid.dart';

/// create by: YanHq
/// create time: 2025/1/16
/// des:
///
const nsKeyedArchiveVersion = 100000;

class NSKeyedArchiver {
  NSKeyedArchiver._();

  static dynamic unarchive(File file) {
    return Unarchive(file.readAsBytesSync()).getTopObject();
  }

  static Uint8List archive(Object object) {
    return Uint8List(0);
  }
}

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

class Archive {
  final primitiveTypes = [int, double, bool, String, Uint8List, UID];
  final inlineTypes = [int, double, bool];

  dynamic input;
  dynamic classMap = {};
  dynamic refMap = <int, UID>{};
  List objects = ['\$null'];

  Uint8List toBytes() {
    if (objects.length == 1) {
      archive(input);
    }
    final d = {
      '\$archiver': 'NSKeyedArchiver',
      '\$version': nsKeyedArchiveVersion,
      '\$top': {'root': UID(1)},
      '\$objects': objects,
    };
    return Plist.dumps(d, fmt: FMT.xml);
  }

  UID archive(dynamic obj) {
    if (obj == null) {
      return UID.nullUID;
    }
    final ref = refMap[obj.hashCode];
    if (ref != null) {
      return ref;
    }

    final index = UID(objects.length);
    refMap[obj.hashCode] = index;

    final cls = obj.runtimeType;
    if (primitiveTypes.contains(cls)) {
      objects.add(obj);
      return index;
    }

    final archiveObj = <String, Object>{};
    objects.add(archiveObj);
    encodeTopLevel(obj, archiveObj);
    return index;
  }

  void encodeTopLevel(dynamic obj, Map<String, Object> archiveObj) {
    if (obj is List) {
      encodeList(obj, archiveObj);
    } else if (obj is Map) {
      encodeMap(obj, archiveObj);
    } else if (obj is Set) {
      encodeSet(obj, archiveObj);
    } else {

    }
  }

  encodeList(List obj, Map<String, Object> archiveObj) {
    final archiverUID = uidForArchiver('NSArray');
    archiveObj['\$class'] = archiverUID;
    archiveObj['NS.objects'] = obj.map((e) => archive(e)).toList();
  }

  encodeMap(Map obj, Map<String, Object> archiveObj) {
    final archiverUID = uidForArchiver('NSDictionary');
    archiveObj['\$class'] = archiverUID;
    archiveObj['NS.keys'] = obj.keys.map((e) => archive(e)).toList();
    archiveObj['NS.objects'] = obj.values.map((e) => archive(e)).toList();
  }

  encodeSet(Set obj, Map<String, Object> archiveObj) {
    final archiverUID = uidForArchiver('NSSet');
    archiveObj['\$class'] = archiverUID;
    archiveObj['NS.objects'] = obj.map((e) => archive(e)).toList();
  }




  UID uidForArchiver(dynamic archiver) {
    var value = classMap[archiver];
    if (value != null) {
      return value;
    }

    value = UID(objects.length);
    classMap[archiver] = value;
    objects.add({
      '\$classes': [archiver],
      '\$classname': archiver,
    });

    return value;
  }

}
