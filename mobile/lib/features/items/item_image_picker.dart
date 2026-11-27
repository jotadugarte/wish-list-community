import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:wish_list_mobile/features/items/image_compressor.dart';

// Gallery/camera picker that compresses before upload (O5A).
// Traceability: [REQ-ITEM-002]
class ItemImagePicker {
  final ImagePicker _picker;

  ItemImagePicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<List<CompressedImageBlob>> pickFromGallery({int maxCount = CompressedImageBlob.maxImages}) async {
    final files = await _picker.pickMultiImage(limit: maxCount);
    return _compressAll(files.take(maxCount));
  }

  Future<CompressedImageBlob?> pickFromCamera() async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return ImageCompressor.compress(rawBytes: Uint8List.fromList(bytes), filename: file.name);
  }

  Future<List<CompressedImageBlob>> _compressAll(Iterable<XFile> files) async {
    final out = <CompressedImageBlob>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      out.add(ImageCompressor.compress(rawBytes: Uint8List.fromList(bytes), filename: file.name));
    }
    return out;
  }
}
