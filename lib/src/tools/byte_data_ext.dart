import 'dart:typed_data';

/// create by: YanHq
/// create time: 2025/2/26
/// des:
///
enum BitSize {
  bit8(1),
  bit16(2),
  bit32(4),
  bit64(8);

  final int size;

  const BitSize(this.size);

  static BitSize? fromSize(int size) {
    try {
      return BitSize.values.firstWhere((element) => element.size == size);
    } catch (e) {
      return null;
    }
  }
}

extension NSKeyedArchivedByteDataWriteExt on ByteData {
  ByteData write(
    int data, {
    BitSize byteSize = BitSize.bit8,
    bool signed = false,
    int offset = 0,
  }) {
    // 创建 ByteData 并写入数据
    Uint8List uint8list = Uint8List(offset + byteSize.size);
    ByteData byteData = ByteData.sublistView(uint8list);
    switch (byteSize) {
      case BitSize.bit8:
        signed
            ? byteData.setInt8(offset, data)
            : byteData.setUint8(offset, data);
        break;
      case BitSize.bit16:
        signed
            ? byteData.setInt16(offset, data)
            : byteData.setUint16(offset, data);
        break;
      case BitSize.bit32:
        signed
            ? byteData.setInt32(offset, data)
            : byteData.setUint32(offset, data);
        break;
      case BitSize.bit64:
        signed
            ? byteData.setInt64(offset, data)
            : byteData.setUint64(offset, data);
        break;
    }
    final combined = Uint8List.view(buffer) + uint8list;
    return ByteData.sublistView(Uint8List.fromList(combined));
  }

  ByteData writeUint8List(Uint8List data) {
    return data.fold(this, (ByteData byteData, int element) {
      return byteData.write(
        element,
        byteSize: BitSize.bit8,
        signed: false,
      );
    });
  }

  ByteData writeDouble(
    double data, {
    BitSize byteSize = BitSize.bit32,
    int offset = 0,
  }) {
    // 创建 ByteData 并写入数据
    Uint8List uint8list = Uint8List(offset + byteSize.size);
    ByteData byteData = ByteData.sublistView(uint8list);
    switch (byteSize) {
      case BitSize.bit32:
        byteData.setFloat32(offset, data);
        break;
      case BitSize.bit64:
        byteData.setFloat64(offset, data);
        break;
      default:
        throw Exception('Invalid byte size');
    }
    final combined = Uint8List.view(buffer) + uint8list;
    return ByteData.sublistView(Uint8List.fromList(combined));
  }
}

extension NSKeyedArchivedByteDataReadExt on ByteData {
  int read({
    required BitSize byteSize,
    int offset = 0,
    bool signed = false,
  }) {
    switch (byteSize) {
      case BitSize.bit8:
        return signed ? getInt8(offset) : getUint8(offset);
      case BitSize.bit16:
        return signed ? getInt16(offset) : getUint16(offset);
      case BitSize.bit32:
        return signed ? getInt32(offset) : getUint32(offset);
      case BitSize.bit64:
        return signed ? getInt64(offset) : getUint64(offset);
    }
  }

  double readDouble({
    required BitSize byteSize,
    int offset = 0,
  }) {
    switch (byteSize) {
      case BitSize.bit32:
        return getFloat32(offset);
      case BitSize.bit64:
        return getFloat64(offset);
      default:
        throw Exception('Invalid byte size');
    }
  }
}
