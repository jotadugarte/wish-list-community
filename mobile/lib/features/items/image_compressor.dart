import 'dart:typed_data';

import 'package:image/image.dart' as img;

// Client-side best-effort compress toward ≤1600px / ≤2MB (O5A).
// Traceability: [REQ-ITEM-002]
class CompressedImageBlob {
  static const maxImages = 3;
  static const maxSide = 1600;
  static const maxBytes = 2 * 1024 * 1024;

  final Uint8List bytes;
  final String filename;
  final String contentType;

  const CompressedImageBlob({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  bool get withinBudget => bytes.lengthInBytes <= maxBytes;
}

class ImageCompressor {
  // [REQ-ITEM-002] Pre-condition: rawBytes non-empty. Post-condition: longest side ≤1600 when decodable.
  static CompressedImageBlob compress({
    required Uint8List rawBytes,
    required String filename,
  }) {
    if (rawBytes.isEmpty) {
      throw ArgumentError('Pre-condition failed: image bytes required');
    }

    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      return CompressedImageBlob(
        bytes: rawBytes,
        filename: filename,
        contentType: 'application/octet-stream',
      );
    }

    final longest = decoded.width > decoded.height ? decoded.width : decoded.height;
    img.Image sized = decoded;
    if (longest > CompressedImageBlob.maxSide) {
      sized = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? CompressedImageBlob.maxSide : null,
        height: decoded.height > decoded.width ? CompressedImageBlob.maxSide : null,
      );
    }

    var quality = 85;
    Uint8List encoded = Uint8List.fromList(img.encodeJpg(sized, quality: quality));
    var guard = 0;
    while (encoded.lengthInBytes > CompressedImageBlob.maxBytes && quality > 40 && guard < 5) {
      quality -= 10;
      encoded = Uint8List.fromList(img.encodeJpg(sized, quality: quality));
      guard += 1;
    }

    final outName = filename.replaceAll(RegExp(r'\.\w+$'), '.jpg');
    final blob = CompressedImageBlob(
      bytes: encoded,
      filename: outName.endsWith('.jpg') ? outName : '$outName.jpg',
      contentType: 'image/jpeg',
    );
    if (blob.bytes.isEmpty) {
      throw StateError('Post-condition failed: compressed bytes empty');
    }
    return blob;
  }
}
