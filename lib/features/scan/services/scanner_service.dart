import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:securescan/core/enums/qr_type.dart';
import 'package:securescan/core/models/history_item.dart';
import 'package:securescan/core/repositories/history_repository.dart';

class ScannerService {
  static QrType classify(String raw, {String? format}) {
    final s = raw.trim().toLowerCase();
    final f = (format ?? '').toLowerCase();

    // Specific Format Handling
    if (f.contains('ean') || f.contains('upc') || f.contains('isbn') || f.contains('product')) {
      return QrType.product;
    }

    // QR Payload Handling
    if (s.startsWith('http://') || s.startsWith('https://')) {
      return QrType.url;
    }
    if (s.startsWith('wifi:')) {
      return QrType.wifi;
    }
    if (s.startsWith('begin:vcard') || s.startsWith('mecard:')) {
      return QrType.contact;
    }
    if (s.startsWith('tel:')) {
      return QrType.phone;
    }
    if (s.startsWith('mailto:')) {
      return QrType.email;
    }
    if (s.startsWith('geo:')) {
      return QrType.location;
    }
    if (s.startsWith('begin:vevent')) {
      return QrType.calendar;
    }
    
    // Generic regex for some types
    if (RegExp(r'^\+?[0-9]{6,15}$').hasMatch(raw.trim())) {
      return QrType.phone;
    }
    if (RegExp(r'^[\w\.\-+]+@[\w\.\-]+\.[A-Za-z]{2,}$').hasMatch(raw.trim())) {
      return QrType.email;
    }

    return QrType.text;
  }

  static Future<HistoryItem?> scanImage(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      debugPrint('Error: Image file does not exist at path: $path');
      return null;
    }
    
    final inputImage = InputImage.fromFilePath(path);
    final barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.all]);
    try {
      final List<Barcode> barcodes = await barcodeScanner.processImage(inputImage);
      if (barcodes.isNotEmpty) {
        final barcode = barcodes.first;
        final raw = barcode.rawValue ?? barcode.displayValue ?? '';
        if (raw.isEmpty) {
          debugPrint('ML Kit detected a barcode but raw value is empty');
          return null;
        }

        final type = classify(raw, format: barcode.format.name);
        debugPrint('ML Kit scanned success: $raw (Type: ${type.name}, Format: ${barcode.format.name})');
        
        return HistoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: type,
          value: raw,
          timestamp: DateTime.now(),
          metadata: {'format': barcode.format.name},
        );
      } else {
        debugPrint('ML Kit processed image but found no barcodes');
      }
    } catch (e) {
      debugPrint('Error scanning image with ML Kit: $e');
    } finally {
      barcodeScanner.close();
    }
    return null;
  }

  static Future<HistoryItem> saveToHistory({
    required String raw,
    required QrType type,
    Map<String, dynamic>? metadata,
    String? imagePath,
    Uint8List? imageBytes,
    String? displayValue,
    bool isCreated = false,
  }) async {
    final item = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      value: raw,
      displayValue: displayValue,
      timestamp: DateTime.now(),
      metadata: metadata,
      imagePath: imagePath,
      imageBytes: imageBytes,
      isCreated: isCreated,
    );
    await HistoryRepository.instance.saveScanItem(item);
    return item;
  }
}
