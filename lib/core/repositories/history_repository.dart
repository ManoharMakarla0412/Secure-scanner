import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_item.dart';
import '../enums/qr_type.dart';
import '../../features/scan/services/scanner_service.dart';

class HistoryRepository {
  static const String _scanHistoryKey = 'scan_history';
  static const String _createdHistoryKey = 'created_history';
  static const int _maxHistoryCount = 200;

  static final HistoryRepository instance = HistoryRepository._();
  HistoryRepository._();

  Future<List<HistoryItem>> getScanHistory() async {
    return _getHistory(_scanHistoryKey);
  }

  Future<List<HistoryItem>> getCreatedHistory() async {
    return _getHistory(_createdHistoryKey);
  }

  Future<void> saveScanItem(HistoryItem item) async {
    await _saveItem(_scanHistoryKey, item);
  }

  Future<void> saveCreatedItem(HistoryItem item) async {
    await _saveItem(_createdHistoryKey, item.copyWith(isCreated: true));
  }

  Future<void> deleteScanItem(String id) async {
    await _deleteItem(_scanHistoryKey, id);
  }

  Future<void> deleteCreatedItem(String id) async {
    await _deleteItem(_createdHistoryKey, id);
  }

  // --- Private Helpers ---

  Future<List<HistoryItem>> _getHistory(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(key) ?? [];
    
    return list.map((e) {
      try {
        final Map<String, dynamic> json = jsonDecode(e);
        return HistoryItem.fromJson(json);
      } catch (err) {
        return _handleLegacyItem(e, key == _createdHistoryKey);
      }
    }).toList().reversed.toList();
  }

  Future<void> _saveItem(String key, HistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(key) ?? [];
    list.add(jsonEncode(item.toJson()));
    if (list.length > _maxHistoryCount) list.removeAt(0);
    await prefs.setStringList(key, list);
  }

  Future<void> _deleteItem(String key, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(key) ?? [];
    
    final updatedList = list.where((e) {
      try {
        final json = jsonDecode(e);
        return (json['id'] ?? json['ts'] ?? '') != id;
      } catch (_) {
        return true; 
      }
    }).toList();
    
    await prefs.setStringList(key, updatedList);
  }

  HistoryItem _handleLegacyItem(String data, bool isCreated) {
    return HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: ScannerService.classify(data),
      value: data,
      timestamp: DateTime.now(),
      isCreated: isCreated,
    );
  }
}

extension HistoryItemExtensions on HistoryItem {
  HistoryItem copyWith({bool? isCreated}) {
    return HistoryItem(
      id: id,
      type: type,
      value: value,
      displayValue: displayValue,
      timestamp: timestamp,
      metadata: metadata,
      imagePath: imagePath,
      imageBytes: imageBytes,
      isCreated: isCreated ?? this.isCreated,
    );
  }
}
