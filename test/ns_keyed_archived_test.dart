import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ns_keyed_archived/ns_keyed_archived.dart';

void main() {
  test('String', () {
    String obj = jsonEncode({
      "account": "admin",
      "password": "111111",
    });
    var bytes = NSKeyedArchiver.archive(obj);
    final result = NSKeyedArchiver.unarchive(bytes);
    expect(obj, result);
  });

  test('int', () {
    int obj = 1050445;
    var bytes = NSKeyedArchiver.archive(obj);
    final result = NSKeyedArchiver.unarchive(bytes);
    expect(obj, result);
  });

  test('double', () {
    double obj = 3.1415926;
    var bytes = NSKeyedArchiver.archive(obj);
    final result = NSKeyedArchiver.unarchive(bytes);
    expect(obj, result);
  });

  test('bool', () {
    bool obj = true;
    var bytes = NSKeyedArchiver.archive(obj);
    final result = NSKeyedArchiver.unarchive(bytes);
    expect(obj, result);
  });

  test('List', () {
    List obj = ['android', 'ios', 'web'];
    var bytes = NSKeyedArchiver.archive(obj);
    final result = NSKeyedArchiver.unarchive(bytes);
    expect(obj, result);
  });

  test('Map', () {
    Map obj = {
      "account": "admin",
      "password": "111111",
      'role': 1,
    };
    var bytes = NSKeyedArchiver.archive(obj);
    final result = NSKeyedArchiver.unarchive(bytes);
    expect(obj, result);
  });

  test('Set', () {
    Set obj = {'windows', 'macOS', 'linux'};
    var bytes = NSKeyedArchiver.archive(obj);
    final result = NSKeyedArchiver.unarchive(bytes);
    expect(obj, result);
  });
}
