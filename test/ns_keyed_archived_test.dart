import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:ns_keyed_archived/src/unarchived.dart';

Future<void> main() async {
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
  };
  obj = {'windows', 'macOS', 'linux'};
  var bytes = NSKeyedArchiver.archive(obj);
  print('main archive: $bytes');
  final result = NSKeyedArchiver.unarchiveFromByte(bytes);
  print('main unarchive: $result');
  if (result is List) {
    print('main equality: ${const IterableEquality().equals(obj, result)}');
  } else if (result is Map) {
    print('main equality: ${const MapEquality().equals(obj, result)}');
  } else if (result is Set) {
    print('main equality: ${const SetEquality().equals(obj, result)}');
  } else {
    print('main equality: ${obj == result}');
  }
}
