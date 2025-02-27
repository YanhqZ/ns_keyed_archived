import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ns_keyed_archived/ns_keyed_archived.dart';

/// create by: YanHq
/// create time: 2025/2/27
/// des:
///
void main() {
  test('write 10,000 times cost', () {
    final obj = json.encode({
      "account": "admin",
      "password": "111111",
      'role': 1,
    });
    final start = DateTime.now();
    for (int i = 0; i < 10000; i++) {
      NSKeyedArchiver.archive(obj);
    }
    debugPrint(
      'write 10,000 times cost: '
      '${DateTime.now().difference(start).inMilliseconds}ms',
    );
  });

  test('read 10,000 times cost', () {
    final obj = json.encode({
      "account": "admin",
      "password": "111111",
      'role': 1,
    });
    var bytes = NSKeyedArchiver.archive(obj);

    final start = DateTime.now();
    for (int i = 0; i < 10000; i++) {
      NSKeyedArchiver.unarchiveFromByte(bytes);
    }
    debugPrint(
      'read 10,000 times cost: '
      '${DateTime.now().difference(start).inMilliseconds}ms',
    );
  });
}
