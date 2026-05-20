import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:securescan/core/config/secrets.dart';

class ProductService {
  static const String BARCODE_LOOKUP_API_KEY = Secrets.barcodeLookupApiKey;
  static const Duration _productLookupTimeout = Duration(seconds: 3);

  /// Try multiple product lookup services (in order) to maximize chance of finding
  /// general retail product metadata (brand / product_name) for the scanned code.
  static Future<Map<String, dynamic>?> fetchProductInfo(String code) async {
    final normalizedCode = code.trim();

    // 1) BarcodeLookup (commercial)
    if (BARCODE_LOOKUP_API_KEY.isNotEmpty) {
      try {
        final uri = Uri.https('api.barcodelookup.com', '/v3/products', {
          'barcode': normalizedCode,
          'key': BARCODE_LOOKUP_API_KEY,
        });
        final resp = await http.get(uri).timeout(_productLookupTimeout);
        if (resp.statusCode == 200) {
          final map = jsonDecode(resp.body) as Map<String, dynamic>;
          if (map['products'] != null && (map['products'] as List).isNotEmpty) {
            final p = (map['products'] as List).first as Map<String, dynamic>;
            final brand = (p['brand'] as String?)?.trim();
            final title = (p['title'] as String?)?.trim();
            final manufacturer = (p['manufacturer'] as String?)?.trim();
            final out = <String, dynamic>{};
            if (brand != null && brand.isNotEmpty) out['brand'] = brand;
            if (title != null && title.isNotEmpty) out['product_name'] = title;
            if (manufacturer != null &&
                manufacturer.isNotEmpty &&
                out['brand'] == null) {
              out['brand'] = manufacturer;
            }
            if (out.isNotEmpty) return out;
          }
        }
      } catch (e) {
        debugPrint('[ProductLookup] BarcodeLookup failed: $e');
      }
    }

    // 2) OpenProductFacts
    try {
      final uri = Uri.https(
        'world.openproductfacts.org',
        '/api/v0/product/$normalizedCode.json',
      );
      final resp = await http.get(uri).timeout(_productLookupTimeout);
      if (resp.statusCode == 200) {
        final map = jsonDecode(resp.body) as Map<String, dynamic>;
        if (map['status'] == 1 && map['product'] != null) {
          final product = map['product'] as Map<String, dynamic>;
          final brandCandidates = <String>[];
          if (product['brands'] is String &&
              (product['brands'] as String).trim().isNotEmpty) {
            brandCandidates.add((product['brands'] as String).trim());
          }
          if (product['brand'] is String &&
              (product['brand'] as String).trim().isNotEmpty) {
            brandCandidates.add((product['brand'] as String).trim());
          }
          final name = (product['product_name'] as String?)?.trim();
          final out = <String, dynamic>{};
          if (brandCandidates.isNotEmpty) out['brand'] = brandCandidates.first;
          if (name != null && name.isNotEmpty) out['product_name'] = name;
          if (out.isNotEmpty) return out;
        }
      }
    } catch (e) {
      debugPrint('[ProductLookup] OpenProductFacts failed: $e');
    }

    // 3) OpenFoodFacts fallback
    try {
      final uri = Uri.https(
        'world.openfoodfacts.org',
        '/api/v0/product/$normalizedCode.json',
      );
      final resp = await http.get(uri).timeout(_productLookupTimeout);
      if (resp.statusCode == 200) {
        final map = jsonDecode(resp.body) as Map<String, dynamic>;
        if (map['status'] == 1 && map['product'] != null) {
          final product = map['product'] as Map<String, dynamic>;
          final brands = (product['brands'] as String?)?.trim();
          final productName = (product['product_name'] as String?)?.trim();
          final out = <String, dynamic>{};
          if (brands != null && brands.isNotEmpty) out['brand'] = brands;
          if (productName != null && productName.isNotEmpty)
            out['product_name'] = productName;
          if (out.isNotEmpty) return out;
        }
      }
    } catch (e) {
      debugPrint('[ProductLookup] OpenFoodFacts failed: $e');
    }

    return null;
  }
}
