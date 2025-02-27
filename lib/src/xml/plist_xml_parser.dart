import 'dart:convert';
import 'dart:typed_data';

import 'package:xml/xml.dart';

import '../plist.dart';

/// create by: YanHq
/// create time: 2025/1/17
/// des:
///
class PlistXmlParser implements PlistFMTParser {
  final List stack = [];
  dynamic currentKey;
  dynamic root;
  final List<String> decoded = [];

  @override
  Map parse(Uint8List archived) {
    final doc = XmlDocument.parse(String.fromCharCodes(archived));
    _traverse(doc.rootElement);
    return root;
  }

  void _traverse(XmlElement element) {
    handleBeginElement(element);

    for (var node in element.children) {
      if (node is XmlElement) {
        _traverse(node);
      } else if (node is XmlText) {
        handleData(node.value);
      }
    }

    handleEndElement(element);
  }

  void handleData(String data) {
    decoded.add(data);
  }

  void handleBeginElement(XmlElement element) {
    decoded.clear();
    switch (element.localName) {
      case 'dict':
        final d = {};
        addObject(d);
        stack.add(d);
        break;
      case 'array':
        final a = {};
        addObject(a);
        stack.add(a);
        break;
      default:
        break;
    }
  }

  void handleEndElement(XmlElement element) {
    decoded.clear();
    switch (element.localName) {
      case 'dict':
        if (currentKey != null) {
          throw Exception('missing value for key \'$currentKey\'');
        }
        stack.removeLast();
        break;
      case 'key':
        if (currentKey != null || stack.lastOrNull is! Map) {
          throw Exception('unexpected key at line');
        }
        currentKey = getData();
        break;
      case 'array':
        stack.removeLast();
        break;
      case 'true':
        addObject(true);
        break;
      case 'false':
        addObject(false);
        break;
      case 'integer':
        addObject(int.parse(getData()));
        break;
      case 'real':
        addObject(double.parse(getData()));
        break;
      case 'string':
        addObject(getData());
        break;
      case 'data':
        addObject(base64.decode(getData()));
        break;
      case 'date':
        addObject(getDateTimeFromString(getData()));
        break;
      default:
        break;
    }
  }

  String getData() {
    final result = decoded.join();
    decoded.clear();
    return result;
  }

  DateTime? getDateTimeFromString(String dateStr) {
    final RegExp dateParser = RegExp(
      r'(?<year>\d{4})(?:-(?<month>\d{2})(?:-(?<day>\d{2})(?:T(?<hour>\d{2})(?::(?<minute>\d{2})(?::(?<second>\d{2}))?)?)?)?)?Z',
    );

    final match = dateParser.firstMatch(dateStr);
    if (match == null) {
      return null;
    }

    final year = int.parse(match.namedGroup('year')!);
    final month = int.parse(match.namedGroup('month') ?? '1');
    final day = int.parse(match.namedGroup('day') ?? '1');
    final hour = int.parse(match.namedGroup('hour') ?? '0');
    final minute = int.parse(match.namedGroup('minute') ?? '0');
    final second = int.parse(match.namedGroup('second') ?? '0');
    return DateTime.utc(year, month, day, hour, minute, second);
  }

  addObject(dynamic value) {
    if (currentKey != null) {
      if (stack.lastOrNull is! Map) {
        throw Exception('unexpected element at line');
      }
      stack.last[currentKey] = value;
      currentKey = null;
    } else if (stack.isEmpty) {
      root = value;
    } else {
      if (stack.lastOrNull is! List) {
        throw Exception('unexpected element at line');
      }
      stack.last.add(value);
    }
  }
}
