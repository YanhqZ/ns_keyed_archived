/// create by: YanHq
/// create time: 2025/1/17
/// des:
///
class UID {
  static UID nullUID = UID(0);

  final dynamic data;

  UID(this.data)
      : assert(data is int, 'data must be an int'),
        assert(BigInt.from(data) < BigInt.one << 64, 'UIDs cannot be >= 2**64'),
        assert(data >= 0, 'UIDs must be positive');

  @override
  String toString() {
    return 'UID($data)';
  }

  @override
  bool operator ==(Object other) {
    return other is UID && other.data == data;
  }

  @override
  int get hashCode => data.hashCode;
}
