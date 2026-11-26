import 'dart:io';
import 'dart:typed_data';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

/// Woher das Belegfoto kommt.
enum PhotoSource { camera, gallery, scanner }

/// Holt ein Foto (Beleg, Produkt) und verkleinert es auf höchstens 1600 px (JPEG, etwa
/// 200 KB), damit der Speicher des Free-Plans reicht.
final class PhotoService {
  const PhotoService();

  static const maxSide = 1600;
  static const quality = 80;

  /// Liefert die verkleinerten Bytes oder `null`, wenn abgebrochen wurde.
  Future<Uint8List?> pick(PhotoSource source) async {
    final path = switch (source) {
      PhotoSource.camera => await _pickWith(ImageSource.camera),
      PhotoSource.gallery => await _pickWith(ImageSource.gallery),
      PhotoSource.scanner => await _scan(),
    };
    if (path == null) return null;
    return await _compress(path);
  }

  Future<String?> _pickWith(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source);
    return file?.path;
  }

  Future<String?> _scan() async {
    final result = await CunningDocumentScanner.scanDocuments(
      noOfPages: 1,
      scannerSource: ScannerSource.cameraAndGallery,
    );
    final images = result?.images ?? const <String>[];
    return images.isEmpty ? null : images.first;
  }

  Future<Uint8List> _compress(String path) async {
    final bytes = await FlutterImageCompress.compressWithFile(
      path,
      minWidth: maxSide,
      minHeight: maxSide,
      quality: quality,
    );
    return bytes ?? await File(path).readAsBytes();
  }
}
