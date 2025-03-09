import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v0';

  Future<({
    Map<String, dynamic>? product,
    bool? isHalal,
    String? halalReason
  })> getProductByBarcode(String barcode) async {
    try {
      if (kDebugMode) {
        debugPrint('==================== OPEN FOOD FACTS API ====================');
        debugPrint('Fetching product from Open Food Facts API: $barcode');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/product/$barcode.json'),
      );

      if (kDebugMode) {
        debugPrint('API Response Status Code: ${response.statusCode}');
        debugPrint('API Response Body: ${response.body}');
      }

      final data = json.decode(response.body);
      if (kDebugMode) {
        debugPrint('Decoded JSON Status: ${data['status']}');
        debugPrint('Decoded JSON Status Verbose: ${data['status_verbose']}');
      }
      
      // Check if product exists
      if (data['status'] == 1) {
        final product = data['product'] as Map<String, dynamic>;
        if (kDebugMode) {
          debugPrint('\nAvailable fields in product:');
          product.forEach((key, value) {
            debugPrint('- $key: $value');
          });
        }
        
        // Check for halal keywords
        final keywords = product['_keywords'] as List<dynamic>?;
        if (kDebugMode) {
          debugPrint('\nKeywords found: $keywords');
        }
        final isHalal = keywords?.contains('halal') ?? false;
        if (kDebugMode) {
          debugPrint('Is Halal: $isHalal');
          debugPrint('===========================================================\n');
        }
        
        return (
          product: product,
          isHalal: isHalal,
          halalReason: isHalal ? 'Product is labeled as Halal in its packaging' : null
        );
      }
      
      if (kDebugMode) {
        debugPrint('Product not found');
        debugPrint('===========================================================\n');
      }
      return (product: null, isHalal: null, halalReason: null);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching product from Open Food Facts: $e');
        debugPrint('===========================================================\n');
      }
      return (product: null, isHalal: null, halalReason: null);
    }
  }
} 