import 'dart:typed_data';
import '../enums/qr_type.dart';

class HistoryItem {
  final String id;
  final QrType type;
  final String value;
  final String? displayValue;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String? imagePath;
  
  /// Transient field for immediate display after scanning. Not persisted.
  final Uint8List? imageBytes; 
  
  final bool isCreated; // true if created, false if scanned

  HistoryItem({
    required this.id,
    required this.type,
    required this.value,
    this.displayValue,
    required this.timestamp,
    this.metadata,
    this.imagePath,
    this.imageBytes,
    this.isCreated = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'value': value,
        'displayValue': displayValue,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
        'imagePath': imagePath,
        'isCreated': isCreated,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: QrType.fromString(json['type'] ?? 'text'),
      value: json['value'] ?? json['raw'] ?? '',
      displayValue: json['displayValue'],
      timestamp: DateTime.parse(json['timestamp'] ?? json['ts'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'] ?? json['data'],
      imagePath: json['imagePath'],
      isCreated: json['isCreated'] ?? false,
    );
  }
}
