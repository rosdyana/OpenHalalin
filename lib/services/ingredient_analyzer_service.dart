import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:halalapp/models/ingredient.dart';

class IngredientAnalyzerService {
  static final _textRecognizer = TextRecognizer();
  final _knownIngredientsCollection = FirebaseFirestore.instance.collection('known_ingredients');
  
  // List of common non-halal ingredients
  static const _nonHalalIngredients = {
    'alcohol': 'Contains alcohol',
    'wine': 'Contains alcohol',
    'beer': 'Contains alcohol',
    'rum': 'Contains alcohol',
    'gelatin': 'May be derived from non-halal sources',
    'pork': 'Contains pork',
    'lard': 'Contains pork fat',
    'bacon': 'Contains pork',
    'ham': 'Contains pork',
    'pepsin': 'May be derived from pork',
    'carmine': 'Derived from insects',
    'cochineal': 'Derived from insects',
    'shellac': 'Derived from insects',
    'l-cysteine': 'May be derived from human hair or duck feathers',
    'e120': 'Carmine (derived from insects)',
    'e441': 'Gelatin (may be from non-halal sources)',
    'e542': 'Bone phosphate (may be from non-halal sources)',
  };

  // Common non-halal ingredients and their reasons
  static const Map<String, String> _commonNonHalalIngredients = {
    'alcohol': 'Contains alcohol which is prohibited',
    'wine': 'Contains alcohol which is prohibited',
    'beer': 'Contains alcohol which is prohibited',
    'rum': 'Contains alcohol which is prohibited',
    'pork': 'Derived from pork which is prohibited',
    'lard': 'Derived from pork which is prohibited',
    'gelatin': 'May be derived from non-halal sources unless specified as halal',
    'pepsin': 'May be derived from pork unless specified as halal',
    'carmine': 'Derived from insects which is questionable',
    'cochineal': 'Derived from insects which is questionable',
    'rennet': 'May be derived from non-halal sources unless specified as halal',
    'ethanol': 'Form of alcohol which is prohibited',
    'tallow': 'May be derived from non-halal sources unless specified as halal',
    'shortening': 'May contain animal fats from non-halal sources',
    'vanilla extract': 'May contain alcohol',
  };

  // Common halal ingredients
  static const List<String> _commonHalalIngredients = [
    'water', 'salt', 'sugar', 'vegetable', 'fruit', 'spice', 'herb',
    'flour', 'rice', 'corn', 'soy', 'wheat', 'oat', 'barley',
    'vegetable oil', 'olive oil', 'sunflower oil', 'palm oil',
    'vitamin', 'mineral', 'natural flavor', 'artificial flavor',
    'citric acid', 'pectin', 'baking soda', 'baking powder',
  ];

  // Keywords that might indicate non-halal sources
  static const List<String> _suspiciousKeywords = [
    'enzyme', 'emulsifier', 'glycerin', 'mono', 'diglycerides',
    'whey', 'lactose', 'casein', 'flavoring', 'natural flavoring',
    'stock', 'broth', 'gelatin', 'collagen', 'albumin',
  ];

  static Future<({List<String> ingredients, List<String> concerns})> analyzeImage(
    File imageFile,
  ) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Extract text that looks like ingredients
      final text = recognizedText.text.toLowerCase();
      final lines = text.split('\n');

      // Look for ingredient list markers
      int startIndex = -1;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains('ingredients:') ||
            lines[i].contains('ingredients') ||
            lines[i].contains('contains:') ||
            lines[i].contains('contains')) {
          startIndex = i;
          break;
        }
      }

      // If we found an ingredients section, process it
      final ingredients = <String>[];
      final concerns = <String>[];

      if (startIndex != -1) {
        // Process the lines after the ingredients marker
        for (int i = startIndex + 1; i < lines.length; i++) {
          final line = lines[i].trim();
          
          // Stop if we hit another section
          if (line.endsWith(':') || line.isEmpty) break;

          // Split by common separators
          final parts = line.split(RegExp(r'[,.]'));
          for (var part in parts) {
            final ingredient = part.trim();
            if (ingredient.isNotEmpty) {
              ingredients.add(ingredient);

              // Check for non-halal ingredients
              for (var entry in _nonHalalIngredients.entries) {
                if (ingredient.contains(entry.key)) {
                  concerns.add('${ingredient}: ${entry.value}');
                  break;
                }
              }
            }
          }
        }
      }

      return (ingredients: ingredients, concerns: concerns);
    } finally {
      _textRecognizer.close();
    }
  }

  Future<(bool, String?)> analyzeIngredient(String ingredientName) async {
    ingredientName = ingredientName.toLowerCase();

    // Check in database first
    try {
      final doc = await _knownIngredientsCollection.doc(ingredientName).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['isHalal'] as bool, data['nonHalalReason'] as String?);
      }
    } catch (e) {
      print('Error checking known ingredients: $e');
    }

    // Check common non-halal ingredients
    for (var entry in _commonNonHalalIngredients.entries) {
      if (ingredientName.contains(entry.key)) {
        return (false, entry.value);
      }
    }

    // Check common halal ingredients
    for (var ingredient in _commonHalalIngredients) {
      if (ingredientName.contains(ingredient)) {
        return (true, null);
      }
    }

    // Check for suspicious keywords
    for (var keyword in _suspiciousKeywords) {
      if (ingredientName.contains(keyword)) {
        return (false, 'Contains $keyword which requires verification of source');
      }
    }

    // If we can't determine, mark as requiring verification
    return (false, 'Requires verification - source unknown');
  }

  Future<void> addKnownIngredient(String name, bool isHalal, {String? nonHalalReason}) async {
    await _knownIngredientsCollection.doc(name.toLowerCase()).set({
      'name': name.toLowerCase(),
      'isHalal': isHalal,
      'nonHalalReason': nonHalalReason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Analyze a list of ingredients
  Future<List<(String, bool, String?)>> analyzeIngredients(List<String> ingredients) async {
    List<(String, bool, String?)> results = [];
    
    for (var ingredient in ingredients) {
      final (isHalal, reason) = await analyzeIngredient(ingredient);
      results.add((ingredient, isHalal, reason));
    }
    
    return results;
  }
} 