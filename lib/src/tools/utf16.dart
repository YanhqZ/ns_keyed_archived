import 'dart:typed_data';

/// create by: YanHq
/// create time: 2025/1/16
/// des: UTF-16 encoding and decoding
///
const UTF16BECodec utf16be = UTF16BECodec();
const UTF16LECodec utf16le = UTF16LECodec();

final class UTF16BECodec {
  const UTF16BECodec();

  Uint8List encode(String input) {
    // Convert the string to UTF-16 encoded bytes (Big Endian)
    List<int> encoded = input.codeUnits;

    // Convert to Big Endian
    Uint8List bigEndian = Uint8List(encoded.length * 2);
    for (int i = 0; i < encoded.length; i++) {
      bigEndian[i * 2] = (encoded[i] >> 8) & 0xFF;
      bigEndian[i * 2 + 1] = encoded[i] & 0xFF;
    }
    return bigEndian;
  }

  String decode(Uint8List data) {
    // Convert Big Endian to characters
    List<int> codeUnits = List<int>.generate(data.length ~/ 2, (i) {
      return (data[i * 2] << 8) | data[i * 2 + 1];
    });
    return String.fromCharCodes(codeUnits);
  }
}

class UTF16LECodec {
  const UTF16LECodec();

  Uint8List encode(String input) {
    // Convert the string to UTF-16 encoded bytes (Little Endian)
    List<int> encoded = input.codeUnits;

    Uint8List littleEndian = Uint8List(encoded.length * 2);
    for (int i = 0; i < encoded.length; i++) {
      littleEndian[i * 2] = encoded[i] & 0xFF;
      littleEndian[i * 2 + 1] = (encoded[i] >> 8) & 0xFF;
    }
    return littleEndian;
  }

  String decode(Uint8List data) {
    // Convert Little Endian to characters
    List<int> codeUnits = List<int>.generate(data.length ~/ 2, (i) {
      return (data[i * 2 + 1] << 8) | data[i * 2];
    });
    return String.fromCharCodes(codeUnits);
  }
}
