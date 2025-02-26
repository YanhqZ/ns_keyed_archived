import 'dart:convert';
import 'dart:typed_data';

import 'package:ns_keyed_archived/src/plist_binary_parser.dart';
import 'package:ns_keyed_archived/src/plist_xml_parser.dart';
import 'package:ns_keyed_archived/src/utf16.dart';

import 'plist_binary_writer.dart';

/// create by: YanHq
/// create time: 2025/1/16
/// des:
///

extension UInt8ListExt on Uint8List {
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

enum FMT {
  xml(
    isDetect: isFmtXml,
    parserBuilder: PlistXmlParser.new,
    writerBuilder: PlistBinaryWriter.new,
  ),
  binary(
    isDetect: isFmtBinary,
    parserBuilder: PlistBinaryParser.new,
    writerBuilder: PlistBinaryWriter.new,
  );

  final bool Function(Uint8List header) isDetect;
  final PlistFMTParser Function() parserBuilder;
  final PlistFMTWriter Function() writerBuilder;

  const FMT(
      {required this.isDetect, required this.parserBuilder, required this.writerBuilder,});
}

abstract class PlistFMTParser {
  Map parse(Uint8List archived);
}

abstract class PlistFMTWriter {
  Uint8List write(Map data);
}

enum FmtXMLEncoding { utf8, utf16be, utf16le }

bool isFmtXml(Uint8List header) {
  final prefixes = [
    ascii.encode('<?xml'),
    ascii.encode('<plist'),
  ];

  // 检查普通前缀
  for (var pfx in prefixes) {
    if (header.startsWith(pfx)) {
      return true;
    }
  }

  // 检查带有 BOM 的编码
  final bomEncodings = [
    (Uint8List.fromList([0xEF, 0xBB, 0xBF]), FmtXMLEncoding.utf8), // BOM_UTF8
    (Uint8List.fromList([0xFE, 0xFF]), FmtXMLEncoding.utf16be), // BOM_UTF16_BE
    (Uint8List.fromList([0xFF, 0xFE]), FmtXMLEncoding.utf16le), // BOM_UTF16_LE
  ];

  for (var (bom, encoding) in bomEncodings) {
    if (!header.startsWith(bom)) {
      continue;
    }

    for (var start in prefixes) {
      final encode = switch (encoding) {
        FmtXMLEncoding.utf8 => utf8.encode(ascii.decode(start)),
        FmtXMLEncoding.utf16be => utf16be.encode(ascii.decode(start)),
        FmtXMLEncoding.utf16le => utf16le.encode(ascii.decode(start)),
      };
      var prefix = bom + encode;
      if (header.sublist(0, prefix.length) == prefix) {
        return true;
      }
    }
  }

  return false;
}

bool isFmtBinary(Uint8List header) {
  return ascii.decode(header.sublist(0, 8)) == "bplist00";
}

class Plist {
  static Map loads(Uint8List archived) {
    final header = archived.sublist(0, 32);
    for (final fmt in FMT.values) {
      if (fmt.isDetect.call(header)) {
        return fmt.parserBuilder.call().parse(archived);
      }
    }
    throw Exception("Invalid file");
  }

  static Uint8List dumps(Map data, {required FMT fmt}) {
    return fmt.writerBuilder.call().write(data);
  }
}
