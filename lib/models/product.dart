import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final String manufacturer;
  final String brand;
  final List<String> ingredients;
  final List<String> searchKeywords;
  final bool isHalal;
  final String? certificationBody;
  final String? nonHalalReason;
  final String? imageUrl;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.manufacturer,
    required this.brand,
    required this.ingredients,
    required this.searchKeywords,
    required this.isHalal,
    this.certificationBody,
    this.nonHalalReason,
    this.imageUrl,
    required this.createdAt,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle createdAt field which could be Timestamp or String
    DateTime createdAt;
    final createdAtData = data['createdAt'];
    if (createdAtData is Timestamp) {
      createdAt = createdAtData.toDate();
    } else if (createdAtData is String) {
      createdAt = DateTime.parse(createdAtData);
    } else {
      createdAt = DateTime.now(); // Fallback to current time if field is missing or invalid
    }

    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      manufacturer: data['manufacturer'] ?? '',
      brand: data['brand'] ?? '',
      ingredients: List<String>.from(data['ingredients'] ?? []),
      searchKeywords: List<String>.from(data['searchKeywords'] ?? []),
      isHalal: data['isHalal'] ?? false,
      certificationBody: data['certificationBody'],
      nonHalalReason: data['nonHalalReason'],
      imageUrl: data['imageUrl'],
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'manufacturer': manufacturer,
      'brand': brand,
      'ingredients': ingredients,
      'searchKeywords': searchKeywords,
      'isHalal': isHalal,
      'certificationBody': certificationBody,
      'nonHalalReason': nonHalalReason,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Generate search keywords for better search functionality
  static List<String> generateSearchKeywords(String text) {
    final keywords = <String>[];
    final normalizedText = text.toLowerCase().trim();
    
    // Add the full text as a keyword
    keywords.add(normalizedText);
    
    // For Latin characters, generate substrings
    if (RegExp(r'^[\x00-\x7F]+$').hasMatch(normalizedText)) {
      final words = normalizedText.split(' ');
      for (var word in words) {
        for (var i = 1; i <= word.length; i++) {
          keywords.add(word.substring(0, i));
        }
      }
    } else {
      // For non-Latin characters (like Chinese), add each character as a keyword
      for (var i = 0; i < normalizedText.length; i++) {
        keywords.add(normalizedText[i]);
        // Also add progressive substrings for non-Latin text
        keywords.add(normalizedText.substring(0, i + 1));
      }
    }
    
    return keywords.toSet().toList(); // Remove duplicates
  }
} 