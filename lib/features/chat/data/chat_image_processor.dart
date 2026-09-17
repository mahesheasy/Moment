import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Resizes and compresses chat photos to HD JPEG bytes for storage upload.
abstract final class ChatImageProcessor {
  static const maxDimension = 2048;
  static const initialQuality = 88;
  static const minQuality = 60;
  static const maxBytes = 900 * 1024;

  static Uint8List prepareForUpload(Uint8List rawBytes) {
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) return rawBytes;

    var image = decoded;
    if (image.width > maxDimension || image.height > maxDimension) {
      image = image.width >= image.height
          ? img.copyResize(image, width: maxDimension)
          : img.copyResize(image, height: maxDimension);
    }

    var quality = initialQuality;
    var encoded = Uint8List.fromList(img.encodeJpg(image, quality: quality));
    while (encoded.length > maxBytes && quality > minQuality) {
      quality -= 5;
      encoded = Uint8List.fromList(img.encodeJpg(image, quality: quality));
    }

    return encoded;
  }
}
