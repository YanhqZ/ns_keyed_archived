import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:ns_keyed_archived/ns_keyed_archived.dart';

void main() {
  dynamic obj = jsonEncode({
    "account": "admin",
    "password": "111111",
  });
  obj = 1050445;
  obj = true;
  obj = ['android', 'ios', 'web'];
  obj = {
    'account': 'admin',
    'password': '111111',
    'role': 1,
  };
  obj = {'windows', 'macOS', 'linux'};

  debugPrint('origin: $obj');
  var bytes = NSKeyedArchiver.archive(obj);
  debugPrint('archive: $bytes');
  final result = NSKeyedArchiver.unarchiveFromByte(bytes);
  debugPrint('unarchive: $result');
  if (result is List) {
    debugPrint('equality: ${const IterableEquality().equals(obj, result)}');
  } else if (result is Map) {
    debugPrint('equality: ${const MapEquality().equals(obj, result)}');
  } else if (result is Set) {
    debugPrint('equality: ${const SetEquality().equals(obj, result)}');
  } else {
    debugPrint('equality: ${obj == result}');
  }
}
