import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

const int maxMedicineImageBytes = 5 * 1024 * 1024;

class SelectedMedicineImage {
  final Uint8List bytes;
  final String fileName;

  const SelectedMedicineImage({
    required this.bytes,
    required this.fileName,
  });
}

class MedicineImageException implements Exception {
  final String message;

  const MedicineImageException(this.message);

  @override
  String toString() => message;
}

Future<SelectedMedicineImage?> selectMedicineImage(
  ImageSource source,
) async {
  try {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 88,
    );
    if (picked == null) return null;

    final fileName = picked.name.trim();
    final extension =
        fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
      throw const MedicineImageException(
        'Choose a JPG, JPEG, PNG, or WebP image.',
      );
    }

    final mimeType = picked.mimeType?.toLowerCase();
    if (mimeType != null &&
        mimeType.isNotEmpty &&
        !const {'image/jpeg', 'image/jpg', 'image/png', 'image/webp'}
            .contains(mimeType)) {
      throw const MedicineImageException(
        'Choose a JPG, JPEG, PNG, or WebP image.',
      );
    }

    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      throw const MedicineImageException(
        'The selected image is empty. Please choose another photo.',
      );
    }
    if (bytes.length > maxMedicineImageBytes) {
      throw const MedicineImageException(
        'Medicine photos must be 5 MB or smaller.',
      );
    }

    final isJpeg = extension == 'jpg' || extension == 'jpeg';
    final validJpeg = bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff;
    final validPng = extension == 'png' &&
        bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a;
    final validWebp = extension == 'webp' &&
        bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';

    if (!(isJpeg && validJpeg) && !validPng && !validWebp) {
      throw const MedicineImageException(
        'The selected file is not a valid JPG, PNG, or WebP image.',
      );
    }

    return SelectedMedicineImage(bytes: bytes, fileName: fileName);
  } on MedicineImageException {
    rethrow;
  } on PlatformException {
    throw MedicineImageException(
      source == ImageSource.camera
          ? 'Unable to access the camera. Check camera permissions and try again.'
          : 'Unable to access the gallery. Check photo permissions and try again.',
    );
  } catch (_) {
    throw MedicineImageException(
      source == ImageSource.camera
          ? 'Could not take the medicine photo. Please try again.'
          : 'Could not select the medicine photo. Please try again.',
    );
  }
}
