import 'dart:convert';
import 'dart:typed_data';

import 'package:ns_keyed_archived/src/native_types/uid.dart';
import 'package:ns_keyed_archived/src/plist.dart';
import 'package:ns_keyed_archived/src/tools/byte_data_ext.dart';
import 'package:ns_keyed_archived/src/tools/map_ext.dart';
import 'package:ns_keyed_archived/src/tools/utf16.dart';

/// create by: YanHq
/// create time: 2025/2/25
/// des:
///
class PlistBinaryWriter extends PlistFMTWriter {
  List<dynamic> objList = [];
  Map<(Type, dynamic), int> objTable = {};
  Map<int, int> objIdTable = {};
  List<int> objectOffsets = [];
  BitSize refBitSize = BitSize.bit8;

  ByteData byteData = ByteData(0);

  @override
  Uint8List write(dynamic data) {
    objList.clear();
    objIdTable.clear();
    _flatten(data);
    final numObjects = objList.length;
    objectOffsets.clear();
    objectOffsets.addAll(List.generate(numObjects, (_) => 0));
    refBitSize = _countToBitSize(numObjects);
    _writeUint8ListToByteData(utf8.encode('bplist00'));
    for (dynamic obj in objList) {
      _writeObject(obj);
    }
    final topObject = _getRefNum(data);
    final offsetTableOffset = byteData.lengthInBytes;
    final offsetSize = _countToBitSize(offsetTableOffset);
    for (int o in objectOffsets) {
      _writeIntToByteData(o, byteSize: offsetSize);
    }

    const sortVersion = 0;
    _writeIntToByteData(sortVersion, offset: 5);
    _writeIntToByteData(offsetSize.size);
    _writeIntToByteData(refBitSize.size);
    _writeIntToByteData(numObjects, byteSize: BitSize.bit64);
    _writeIntToByteData(topObject, byteSize: BitSize.bit64);
    _writeIntToByteData(offsetTableOffset, byteSize: BitSize.bit64);

    return byteData.buffer.asUint8List();
  }

  _flatten(dynamic data) {
    if (data is String ||
        data is int ||
        data is double ||
        data is DateTime ||
        data is Uint8List) {
      if (objTable.containsKey((data.runtimeType, data))) {
        return;
      }
    } else if (objIdTable.containsKey(data.hashCode)) {
      return;
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
      final keys = [];
      final values = [];
      for (var item in data.sortWithKey().entries) {
        if (item.key is! String) {
          throw Exception('Key must be a string');
        }
        keys.add(item.key);
        values.add(item.value);
      }
      for (var o in keys + values) {
        _flatten(o);
      }
    } else if (data is List || data is Record) {
      data.forEach((o) {
        _flatten(o);
      });
    }
  }

  BitSize _countToBitSize(int count) {
    if (count < 1 << 8) {
      return BitSize.bit8;
    } else if (count < 1 << 16) {
      return BitSize.bit16;
    } else if (count < 1 << 32) {
      return BitSize.bit32;
    } else {
      return BitSize.bit64;
    }
  }

  _writeUint8ListToByteData(Uint8List typeData) {
    byteData = byteData.writeUint8List(typeData);
  }

  _writeIntToByteData(
    int data, {
    BitSize byteSize = BitSize.bit8,
    bool signed = false,
    int offset = 0,
  }) {
    byteData = byteData.write(
      data,
      byteSize: byteSize,
      signed: signed,
      offset: offset,
    );
  }

  _writeDoubleToByteData(
    double data, {
    required BitSize byteSize,
    int offset = 0,
  }) {
    byteData = byteData.writeDouble(
      data,
      byteSize: byteSize,
      offset: offset,
    );
  }

  dynamic _getRefNum(dynamic value) {
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

  _writeSize(int token, int size) {
    if (size < 15) {
      _writeIntToByteData(token | size);
    } else if (size < 1 << 8) {
      _writeIntToByteData(token | 0x0f);
      _writeIntToByteData(0x10);
      _writeIntToByteData(size);
    } else if (size < 1 << 16) {
      _writeIntToByteData(token | 0x0f);
      _writeIntToByteData(0x11);
      _writeIntToByteData(size, byteSize: BitSize.bit16);
    } else if (size < 1 << 32) {
      _writeIntToByteData(token | 0x0f);
      _writeIntToByteData(0x12);
      _writeIntToByteData(size, byteSize: BitSize.bit32);
    } else {
      _writeIntToByteData(token | 0x0f);
      _writeIntToByteData(0x13);
      _writeIntToByteData(size, byteSize: BitSize.bit64);
    }
  }

  _writeObject(dynamic value) {
    final ref = _getRefNum(value);
    objectOffsets[ref] = byteData.lengthInBytes;
    if (value == null) {
      _writeUint8ListToByteData(utf8.encode('\x00'));
    } else if (value is bool) {
      _writeUint8ListToByteData(utf8.encode(value ? '\x09' : '\x08'));
    } else if (value is int) {
      if (value < 0) {
        _writeIntToByteData(0x13);
        _writeIntToByteData(value, byteSize: BitSize.bit64, signed: true);
      } else if (value < 1 << 8) {
        _writeIntToByteData(0x10);
        _writeIntToByteData(value);
      } else if (value < 1 << 16) {
        _writeIntToByteData(0x11);
        _writeIntToByteData(value, byteSize: BitSize.bit16);
      } else if (value < 1 << 32) {
        _writeIntToByteData(0x12);
        _writeIntToByteData(value, byteSize: BitSize.bit32);
      } else if (value < 1 << 63) {
        _writeIntToByteData(0x13);
        _writeIntToByteData(value, byteSize: BitSize.bit64);
      } else if (value < 1 << 64) {
        _writeIntToByteData(0x14);
        var highBits = (value >> 64) & 0xFFFFFFFFFFFFFFFF;
        var lowBits = value & 0xFFFFFFFFFFFFFFFF;
        _writeIntToByteData(highBits, byteSize: BitSize.bit64, signed: true);
        _writeIntToByteData(lowBits, byteSize: BitSize.bit64, signed: true);
      } else {
        throw Exception('Integer too large');
      }
    } else if (value is double) {
      _writeIntToByteData(0x23);
      _writeDoubleToByteData(value, byteSize: BitSize.bit64);
    } else if (value is DateTime) {
      final s = value.difference(DateTime.utc(2001, 1, 1)).inSeconds;
      _writeIntToByteData(0x33);
      _writeDoubleToByteData(s.toDouble(), byteSize: BitSize.bit64);
    } else if (value is Uint8List) {
      _writeSize(0x40, value.length);
    } else if (value is String) {
      Uint8List t;
      try {
        t = ascii.encode(value);
        _writeSize(0x50, value.length);
      } catch (e) {
        t = utf16be.encode(value);
        _writeSize(0x60, value.length ~/ 2);
      }
      _writeUint8ListToByteData(t);
    } else if (value is UID) {
      if (value.data < 0) {
        throw Exception('UID must be positive');
      } else if (value.data < 1 << 8) {
        _writeIntToByteData(0x80);
        _writeIntToByteData(value.data);
      } else if (value.data < 1 << 16) {
        _writeIntToByteData(0x81);
        _writeIntToByteData(value.data, byteSize: BitSize.bit16);
      } else if (value.data < 1 << 32) {
        _writeIntToByteData(0x83);
        _writeIntToByteData(value.data, byteSize: BitSize.bit32);
      } else if (value.data < 1 << 64) {
        _writeIntToByteData(0x87);
        _writeIntToByteData(value.data, byteSize: BitSize.bit64);
      } else {
        throw Exception('UID too large');
      }
    } else if (value is List || value is Record) {
      final refs = value.map((o) => _getRefNum(o));
      final s = refs.length;
      _writeSize(0xA0, s);
      for (var ref in refs) {
        _writeIntToByteData(ref, byteSize: refBitSize);
      }
    } else if (value is Map) {
      final keyRefs = <int>[];
      final valueRefs = <int>[];
      for (var item in value.sortWithKey().entries) {
        if (item.key is! String) {
          throw Exception('Key must be a string');
        }
        keyRefs.add(_getRefNum(item.key));
        valueRefs.add(_getRefNum(item.value));
      }
      final s = keyRefs.length;
      _writeSize(0xD0, s);
      for (var o in keyRefs) {
        _writeIntToByteData(o, byteSize: refBitSize);
      }
      for (var o in valueRefs) {
        _writeIntToByteData(o, byteSize: refBitSize);
      }
    } else {
      throw Exception('Invalid object');
    }
  }
}
