/// create by: YanHq
/// create time: 2025/2/27
/// des:
///
extension NSKeyedArchivedMapExt on Map {
  /// 判断是否以指定的Uint8List开头
  Map sortWithKey() {
    return Map.fromEntries(entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString())));
  }
}
