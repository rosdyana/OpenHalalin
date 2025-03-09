import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String barcode;
  final String name;
  final String brand;
  final String description;
  final String category;
  final String manufacturer;
  final List<String> ingredients;
  final bool isHalal;
  final String? nonHalalReason;
  final String? imageUrl;
  final String? halalCertificateUrl;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.brand,
    required this.description,
    required this.category,
    required this.manufacturer,
    required this.ingredients,
    required this.isHalal,
    this.nonHalalReason,
    this.imageUrl,
    this.halalCertificateUrl,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      barcode: data['barcode'] ?? '',
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      manufacturer: data['manufacturer'] ?? '',
      ingredients: List<String>.from(data['ingredients'] ?? []),
      isHalal: data['isHalal'] ?? false,
      nonHalalReason: data['nonHalalReason'],
      imageUrl: data['imageUrl'],
      halalCertificateUrl: data['halalCertificateUrl'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'description': description,
      'category': category,
      'manufacturer': manufacturer,
      'ingredients': ingredients,
      'isHalal': isHalal,
      'nonHalalReason': nonHalalReason,
      'imageUrl': imageUrl,
      'halalCertificateUrl': halalCertificateUrl,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static List<String> generateSearchKeywords(String text) {
    final words = text.toLowerCase().split(RegExp(r'[^\w\s]'));
    final keywords = <String>{};
    
    for (var word in words) {
      word = word.trim();
      if (word.isEmpty) continue;
      
      // Add full word
      keywords.add(word);
      
      // Add partial matches (minimum 3 characters)
      if (word.length > 3) {
        for (var i = 3; i < word.length; i++) {
          keywords.add(word.substring(0, i));
        }
      }
    }
    
    return keywords.toList();
  }
} 