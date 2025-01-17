import 'dart:convert';
import 'dart:typed_data';

import 'plist.dart';
import 'uid.dart';
import 'utf16.dart';

/// create by: YanHq
/// create time: 2025/1/17
/// des:
///
class PlistBinaryParser implements PlistFMTParser {
  late ByteData archive;
  late int _refSize;
  late List<int> _objectOffsets;
  late List<dynamic> _objects;
  int pOffset = 0;

  @override
  Map parse(Uint8List data) {
    pOffset = data.length - 32;
    if (pOffset <= 0) {
      throw Exception("Invalid file");
    }
    archive = ByteData.sublistView(data);
    final trailer = ByteData.sublistView(data.sublist(pOffset));
    final offsetSize = trailer.getUint8(6);
    _refSize = trailer.getUint8(7);
    final numObjects = trailer.getUint64(8);
    final topObject = trailer.getUint64(16);
    final offsetTableOffset = trailer.getUint64(24);

    pOffset = offsetTableOffset;
    _objectOffsets = _readInts(numObjects, offsetSize);
    _objects = List.filled(numObjects, null);

    final result = _readObject(topObject);
    return result;
  }

  List<int> _readInts(int n, int size) {
    final result = <int>[];
    if ({1, 2, 4, 8}.contains(size)) {
      for (int i = 0; i < n; i++) {
        result.add(_bytesToInt(size));
      }
    } else {
      if (size == 0) {
        throw Exception("Invalid file");
      }
      final ByteData byteData = archive.buffer.asByteData(pOffset, size * n);
      for (int i = 0; i < size * n; i += size) {
        int value = 0;
        for (int j = 0; j < size; j++) {
          value = (value << 8) + byteData.getUint8(i + j);
        }
        result.add(value);
      }
    }

    return result;
  }

  dynamic _readObject(int ref) {
    var result = _objects[ref];
    if (result != null) {
      return result;
    }

    final offset = _objectOffsets[ref];
    pOffset = offset;
    final token = archive.buffer.asUint8List(pOffset, 1)[0];
    pOffset += 1;
    final tokenH = token & 0xF0;
    final tokenL = token & 0x0F;

    if (token == 0x00) {
      result = null;
    } else if (token == 0x08) {
      result = false;
    } else if (token == 0x09) {
      result = true;
    } else if (token == 0x0f) {
      result = ascii.encode('');
    } else if (tokenH == 0x10) {
      // int
      final size = 1 << tokenL;
      result = _bytesToInt(size, signed: tokenL >= 3);
    } else if (token == 0x22) {
      // double
      result = _bytesToDouble(4);
    } else if (token == 0x23) {
      // double
      result = _bytesToDouble(8);
    } else if (token == 0x33) {
      // date
      var seconds = _bytesToDouble(8);
      // timestamp 0 of binary plist corresponds to 1/1/2001 (year of Mac OS X 10.0), instead of 1/1/1970.
      var date = DateTime(2001, 1, 1).add(Duration(seconds: seconds.toInt()));
      return date.add(date.timeZoneOffset).toUtc();
    } else if (tokenH == 0x40) {
      // data
      final size = _getSize(tokenL);
      result = archive.buffer.asUint8List(pOffset, size);
      pOffset += size;
    } else if (tokenH == 0x50) {
      // ascii string
      final size = _getSize(tokenL);
      result = ascii.decode(archive.buffer.asUint8List(pOffset, size));
      pOffset += size;
    } else if (tokenH == 0x60) {
      // unicode string
      final size = _getSize(tokenL);
      result = utf16be.decode(archive.buffer.asUint8List(pOffset, size * 2));
      pOffset += size * 2;
    } else if (tokenH == 0x80) {
      // uid
      final size = 1 + tokenL;
      result = UID(_bytesToInt(size));
    } else if (tokenH == 0xA0) {
      // array
      final size = _getSize(tokenL);
      final objRefs = _readRefs(size);
      result = objRefs.map((ref) => _readObject(ref)).toList();
      _objects[ref] = result;
    } else if (tokenH == 0xD0) {
      // map
      final size = _getSize(tokenL);
      final keyRefs = _readRefs(size);
      final objRefs = _readRefs(size);
      result = {};
      _objects[ref] = result;
      for (var i = 0; i < size; i++) {
        result[_readObject(keyRefs[i])] = _readObject(objRefs[i]);
      }
    } else {
      throw Exception("Invalid file");
    }

    _objects[ref] = result;
    return result;
  }

  List<int> _readRefs(int n) {
    return _readInts(n, _refSize);
  }

  int _getSize(int tokenL) {
    if (tokenL == 0xF) {
      final m = archive.buffer.asInt8List(pOffset, 1)[0] & 0x3;
      pOffset += 1;
      final s = 1 << m;
      return _bytesToInt(s);
    }
    return tokenL;
  }

  int _bytesToInt(int byteSize, {int offset = 0, bool signed = false}) {
    final byteData = ByteData.view(archive.buffer, pOffset, byteSize);
    final result = switch (byteSize) {
      1 => signed ? byteData.getInt8(offset) : byteData.getUint8(offset),
      2 => signed ? byteData.getInt16(offset) : byteData.getUint16(offset),
      4 => signed ? byteData.getInt32(offset) : byteData.getUint32(offset),
      8 => signed ? byteData.getInt64(offset) : byteData.getUint64(offset),
      _ => throw Exception("Undefined ByteSize: $byteSize"),
    };
    pOffset += byteSize;
    return result;
  }

  double _bytesToDouble(
    int byteSize, {
    int offset = 0,
  }) {
    final byteData = ByteData.view(archive.buffer, pOffset, byteSize);
    final result = switch (byteSize) {
      4 => byteData.getFloat32(offset),
      8 => byteData.getFloat64(offset),
      _ => throw Exception("Undefined ByteSize: $byteSize"),
    };
    pOffset += byteSize;
    return result;
  }
}
