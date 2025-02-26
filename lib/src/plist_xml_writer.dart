import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:ns_keyed_archived/src/plist.dart';

/// create by: YanHq
/// create time: 2025/2/26
/// des:
///
const plistXMLHeader = """\
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
""";

class PlistXmlWriter extends PlistFMTWriter {
  final stack = [];
  Uint8List bytes = Uint8List(0);
  final indent = '\t';
  int indentLevel = 0;

  @override
  Uint8List write(Map data) {
    writeInts(ascii.encode(plistXMLHeader), byteSize: 1);
    writeln("<plist version=\"1.0\">");
    writeValue(data);
    writeln("</plist>");
    return bytes;
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

  writeln(String line) {
    if (line.isNotEmpty) {
      List.generate(indentLevel, (_) {
        writeInts(utf8.encode(indent), byteSize: 1);
        writeInts(utf8.encode(line), byteSize: 1);
      });
    }
    writeInts(ascii.encode('\n'), byteSize: 1);
  }

  writeValue(dynamic value) {
    if (value is String) {
      simpleElement(element: 'string', value: value);
    } else if (value is bool) {
      simpleElement(element: value ? 'true' : 'false');
    } else if (value is int) {
      if (-1 << 63 <= value && value < 1 << 64) {
        simpleElement(element: 'integer', value: '$value');
      } else {
        throw Exception('unsupported int value: $value');
      }
    } else if (value is double) {
      simpleElement(element: 'real', value: '$value');
    } else if (value is Map) {
      writeDict(value);
    } else if (value is Uint8List) {
      writeBytes(value);
    } else if (value is DateTime) {
      simpleElement(element: 'date', value: _dateToString(value));
    } else if (value is List || value is Record) {
      writeArray(value);
    } else {
      throw Exception('unsupported type: ${value.runtimeType}');
    }
  }

  simpleElement({
    required String element,
    String? value,
  }) {
    if (value != null) {
      writeln('<$element>${_escape(value.toString())}</$element>');
    } else {
      writeln('<$element/>');
    }
  }

  beginElement(String element) {
    stack.add(element);
    writeln('<$element>');
    indentLevel++;
  }

  endElement(String element) {
    assert(indentLevel > 0);
    assert(stack.removeLast() == element);
    indentLevel--;
    writeln('</$element>');
  }

  String _escape(String value) {
    final pattern = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]');
    if (pattern.hasMatch(value)) {
      throw Exception(
          'strings can\'t contains control characters; use bytes instead');
    }
    return value
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  writeDict(Map dict) {
    if (dict.isNotEmpty) {
      beginElement('dict');
      final items = dict.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (var item in items) {
        if (item.key is! String) {
          throw Exception('Key must be a string');
        }
        simpleElement(element: 'key', value: item.key);
        writeValue(item.value);
      }
      endElement('dict');
    } else {
      simpleElement(element: 'dict');
    }
  }

  writeArray(List array) {
    if (array.isNotEmpty) {
      beginElement('array');
      for (var item in array) {
        writeValue(item);
      }
      endElement('array');
    } else {
      simpleElement(element: 'array');
    }
  }

  writeBytes(Uint8List value) {
    beginElement('data');
    indentLevel--;
    final str = indent.replaceAll('\t', " " * 8) * indentLevel;
    final maxLineLength = max(16, 76 - str.length);
    for (final line
        in _encodeBase64(value, maxLineLength: maxLineLength).split('\n')) {
      if (line.isNotEmpty) {
        writeln(line);
      }
    }
    indentLevel++;
    endElement('data');
  }

  String _encodeBase64(Uint8List data, {int maxLineLength = 76}) {
    final maxBinSize = (maxLineLength ~/ 4) * 3;
    final buffer = StringBuffer();
    for (var i = 0; i < data.length; i += maxBinSize) {
      final chunk = data.sublist(
          i, i + maxBinSize > data.length ? data.length : i + maxBinSize);
      final encodedChunk = base64.encode(chunk);
      buffer.writeln(encodedChunk);
    }
    return buffer.toString();
  }

  String _dateToString(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}T'
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}:'
        '${d.second.toString().padLeft(2, '0')}Z';
  }
}
