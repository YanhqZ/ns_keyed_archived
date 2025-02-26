import 'dart:convert';
import 'dart:typed_data';

import 'package:ns_keyed_archived/src/plist.dart';
import 'package:ns_keyed_archived/src/uid.dart';
import 'package:ns_keyed_archived/src/utf16.dart';

/// create by: YanHq
/// create time: 2025/2/25
/// des:
///
class PlistBinaryWriter extends PlistFMTWriter {
  List<dynamic> objList = [];
  Map<(Type, dynamic), int> objTable = {};
  Map<int, int> objIdTable = {};
  List<int> objectOffsets = [];
  int refSize = 0;

  // int pOffset = 0;
  Uint8List bytes = Uint8List(0);

  @override
  Uint8List write(dynamic data) {
    objList.clear();
    objIdTable.clear();
    flatten(data);
    final numObjects = objList.length;
    objectOffsets.clear();
    objectOffsets.addAll(List.generate(numObjects, (_) => 0));
    refSize = countToSize(numObjects);
    writeInts(ascii.encode('bplist00'), byteSize: 1);
    for (dynamic obj in objList) {
      writeObject(obj);
    }
    final topObject = getRefNum(data);
    final offsetTableOffset = bytes.length;
    final offsetSize = countToSize(offsetTableOffset);
    for (int o in objectOffsets) {
      writeInt(o, byteSize: offsetSize);
    }

    const sortVersion = 0;
    writeInt(sortVersion, byteSize: 1, offset: 5);
    writeInt(offsetSize, byteSize: 1);
    writeInt(refSize, byteSize: 1);
    writeInt(numObjects, byteSize: 8);
    writeInt(topObject, byteSize: 8);
    writeInt(offsetTableOffset, byteSize: 8);

    return bytes;
  }

  flatten(dynamic data) {
    if (data is String ||
        data is int ||
        data is double ||
        data is DateTime ||
        data is Uint8List) {
      if (objTable.containsKey((data.runtimeType, data))) {
        return;
      }
    } else {
      objIdTable.containsKey(data.hashCode);
    }
    final refNum = objList.length;
    objList.add(data);
    if (data is String ||
        data is int ||
        data is double ||
        data is DateTime ||
        data is Uint8List) {
      objTable[(data.runtimeType, data)] = refNum;
    } else {
      objIdTable[data.hashCode] = refNum;
    }

    if (data is Map) {
      final items = data.entries.toList();
      items.sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      final keys = [];
      final values = [];
      for (var item in items) {
        if (item.key is! String) {
          throw Exception('Key must be a string');
        }
        keys.add(item.key);
        values.add(item.value);
      }
      for (var o in keys + values) {
        flatten(o);
      }
    } else if (data is List || data is Record) {
      data.forEach((o) {
        flatten(o);
      });
    }
  }

  int countToSize(int count) {
    if (count < 1 << 8) {
      return 1;
    } else if (count < 1 << 16) {
      return 2;
    } else if (count < 1 << 32) {
      return 4;
    } else {
      return 8;
    }
  }

  writeInts(List<int> typeData, {required int byteSize, bool signed = false}) {
    for (int i = 0; i < typeData.length; i++) {
      writeInt(typeData[i], byteSize: byteSize, signed: signed);
    }
  }

  writeInt(
    int data, {
    required int byteSize,
    bool signed = false,
    int offset = 0,
  }) {
    // 创建 ByteData 并写入数据
    ByteData byteData = ByteData(offset + byteSize);
    switch (byteSize) {
      case 1:
        signed
            ? byteData.setInt8(offset, data)
            : byteData.setUint8(offset, data);
        break;
      case 2:
        signed
            ? byteData.setInt16(offset, data)
            : byteData.setUint16(offset, data);
        break;
      case 4:
        signed
            ? byteData.setInt32(offset, data)
            : byteData.setUint32(offset, data);
        break;
      case 8:
        signed
            ? byteData.setInt64(offset, data)
            : byteData.setUint64(offset, data);
        break;
      default:
        throw Exception('Invalid byte size');
    }
    bytes = Uint8List.fromList(bytes + byteData.buffer.asUint8List());
  }

  writeDouble(
    double data, {
    required int byteSize,
    int offset = 0,
  }) {
    // 创建 ByteData 并写入数据
    ByteData byteData = ByteData(byteSize + offset);
    switch (byteSize) {
      case 4:
        byteData.setFloat32(offset, data);
        break;
      case 8:
        byteData.setFloat64(offset, data);
        break;
      default:
        throw Exception('Invalid byte size');
    }
    bytes = Uint8List.fromList(bytes + byteData.buffer.asUint8List());
  }

  dynamic getRefNum(dynamic value) {
    if (value is String ||
        value is int ||
        value is double ||
        value is DateTime ||
        value is Uint8List) {
      return objTable[(value.runtimeType, value)];
    } else {
      return objIdTable[value.hashCode];
    }
  }

  writeSize(int token, int size) {
    if (size < 15) {
      writeInt(token | size, byteSize: 1);
    } else if (size < 1 << 8) {
      writeInt(token | 0x0f, byteSize: 1);
      writeInt(0x10, byteSize: 1);
      writeInt(size, byteSize: 1);
    } else if (size < 1 << 16) {
      writeInt(token | 0x0f, byteSize: 1);
      writeInt(0x11, byteSize: 1);
      writeInt(size, byteSize: 2);
    } else if (size < 1 << 32) {
      writeInt(token | 0x0f, byteSize: 1);
      writeInt(0x12, byteSize: 1);
      writeInt(size, byteSize: 4);
    } else {
      writeInt(token | 0x0f, byteSize: 1);
      writeInt(0x13, byteSize: 1);
      writeInt(size, byteSize: 8);
    }
  }

  writeObject(dynamic value) {
    final ref = getRefNum(value);
    objectOffsets[ref] = bytes.length;

    if (value == null) {
      writeInts(ascii.encode('\x00'), byteSize: 1);
    } else if (value is bool) {
      writeInts(ascii.encode(value ? '\x09' : '\x08'), byteSize: 1);
    } else if (value is int) {
      if (value < 0) {
        writeInt(0x13, byteSize: 1);
        writeInt(value, byteSize: 8, signed: true);
      } else if (value < 1 << 8) {
        writeInt(0x10, byteSize: 1);
        writeInt(value, byteSize: 1);
      } else if (value < 1 << 16) {
        writeInt(0x11, byteSize: 1);
        writeInt(value, byteSize: 2);
      } else if (value < 1 << 32) {
        writeInt(0x12, byteSize: 1);
        writeInt(value, byteSize: 4);
      } else if (value < 1 << 63) {
        writeInt(0x13, byteSize: 1);
        writeInt(value, byteSize: 8);
      } else if (value < 1 << 64) {
        writeInt(0x14, byteSize: 1);
        var highBits = (value >> 64) & 0xFFFFFFFFFFFFFFFF;
        var lowBits = value & 0xFFFFFFFFFFFFFFFF;
        writeInt(highBits, byteSize: 8, signed: true);
        writeInt(lowBits, byteSize: 8, signed: true);
      } else {
        throw Exception('Integer too large');
      }
    } else if (value is double) {
      writeInt(0x23, byteSize: 1);
      writeDouble(value, byteSize: 4);
    } else if (value is DateTime) {
      final s = value.difference(DateTime.utc(2001, 1, 1)).inSeconds;
      writeInt(0x33, byteSize: 1);
      writeDouble(s.toDouble(), byteSize: 4);
    } else if (value is Uint8List) {
      writeSize(0x40, value.length);
    } else if (value is String) {
      Uint8List t;
      try {
        t = ascii.encode(value);
        writeSize(0x50, value.length);
      } catch (e) {
        t = utf16be.encode(value);
        writeSize(0x60, value.length ~/ 2);
      }
      writeInts(t, byteSize: 1);
    } else if (value is UID) {
      if (value.data < 0) {
        throw Exception('UID must be positive');
      } else if (value.data < 1 << 8) {
        writeInt(0x80, byteSize: 1);
        writeInt(value.data, byteSize: 1);
      } else if (value.data < 1 << 16) {
        writeInt(0x81, byteSize: 1);
        writeInt(value.data, byteSize: 2);
      } else if (value.data < 1 << 32) {
        writeInt(0x83, byteSize: 1);
        writeInt(value.data, byteSize: 4);
      } else if (value.data < 1 << 64) {
        writeInt(0x87, byteSize: 1);
        writeInt(value.data, byteSize: 8);
      } else {
        throw Exception('UID too large');
      }
    } else if (value is List || value is Record) {
      final refs = value.map((o) => getRefNum(o));
      final s = refs.length;
      writeSize(0xA0, s);
      for (var ref in refs) {
        writeInt(ref, byteSize: refSize);
      }
    } else if (value is Map) {
      final keyRefs = <int>[];
      final valueRefs = <int>[];
      final rootItems = value.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      for (var item in rootItems) {
        if (item.key is! String) {
          throw Exception('Key must be a string');
        }
        keyRefs.add(getRefNum(item.key));
        valueRefs.add(getRefNum(item.value));
      }
      final s = keyRefs.length;
      writeSize(0xD0, s);
      for (var o in keyRefs) {
        writeInt(o, byteSize: refSize);
      }
      for (var o in valueRefs) {
        writeInt(o, byteSize: refSize);
      }
    } else {
      throw Exception('Invalid object');
    }
  }
}
