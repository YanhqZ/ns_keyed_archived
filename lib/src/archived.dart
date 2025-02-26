import 'dart:core';
import 'dart:typed_data';

import 'package:ns_keyed_archived/src/archived_types.dart';
import 'package:ns_keyed_archived/src/uid.dart';

import 'plist.dart';

/// create by: YanHq
/// create time: 2025/2/24
/// des:
///
class Archive {
  final dynamic input;
  final Map<String, dynamic> classMap = {};
  final Map<int, UID> refMap = {};
  final List<dynamic> objects;

  Archive({required this.input}) : objects = ['\$null'];

  Uint8List toBytes() {
    if (objects.length == 1) {
      archive(input);
    }
    final d = {
      '\$archiver': 'NSKeyedArchiver',
      '\$version': nsKeyedArchiveVersion,
      '\$objects': objects,
      '\$top': {'root': UID(1)}
    };
    return FMT.binary.writerBuilder.call().write(d);
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
    if (obj is int ||
        obj is double ||
        obj is bool ||
        obj is String ||
        obj is Uint8List ||
        obj is UID) {
      objects.add(obj);
      return index;
    }

    final archiveObj = <String, dynamic>{};
    objects.add(archiveObj);
    encodeTopLevel(obj, archiveObj);
    return index;
  }

  void encodeTopLevel(obj, Map<String, dynamic> archiveObj) {
    if (obj is List) {
      encodeList(obj, archiveObj);
    } else if (obj is Map) {
      encodeMap(obj, archiveObj);
    } else if (obj is Set) {
      encodeSet(obj, archiveObj);
    } else {
      throw Exception('Unsupported type: ${obj.runtimeType}');
    }
  }

  UID uidForArchiver(String type) {
    var val = classMap[type];
    if (val != null) {
      return val;
    }
    val = UID(objects.length);
    classMap[type] = val;
    objects.add({
      '\$classes': [type],
      '\$classname': type,
    });
    return val;
  }

  void encodeList(List obj, Map<String, dynamic> archiveObj) {
    final archiverUid = uidForArchiver('NSArray');
    archiveObj['\$class'] = archiverUid;
    archiveObj['NS.objects'] = obj.map((e) => archive(e)).toList();
  }

  void encodeMap(Map obj, Map<String, dynamic> archiveObj) {
    final archiverUid = uidForArchiver('NSDictionary');
    archiveObj['\$class'] = archiverUid;
    archiveObj['NS.keys'] = obj.keys.map((e) => archive(e)).toList();
    archiveObj['NS.objects'] = obj.values.map((e) => archive(e)).toList();
  }

  void encodeSet(Set obj, Map<String, dynamic> archiveObj) {
    final archiverUid = uidForArchiver('NSSet');
    archiveObj['\$class'] = archiverUid;
    archiveObj['NS.objects'] = obj.map((e) => archive(e)).toList();
  }
}
