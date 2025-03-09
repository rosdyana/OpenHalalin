import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:halalapp/models/product.dart';
import 'package:halalapp/services/ingredient_analyzer_service.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'products';
  final _ingredientAnalyzer = IngredientAnalyzerService();

  // Search products
  Stream<List<Product>> searchProducts(String query) {
    if (query.isEmpty) {
      // Return recent products if no query
      return _firestore
          .collection(collection)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
      });
    }

    // Convert query to lowercase for case-insensitive search
    query = query.toLowerCase();

    // Search using the searchKeywords array
    return _firestore
        .collection(collection)
        .where('searchKeywords', arrayContains: query)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
  }

  // Add a new product
  Future<void> addProduct(
    String barcode,
    String name,
    String brand,
    List<String> ingredients,
    String? imageUrl, {
    bool? manualIsHalal,
    String? manualNonHalalReason,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User must be logged in to add products');

    // Generate search keywords
    final List<String> searchKeywords = Product.generateSearchKeywords(name);
    searchKeywords.addAll(Product.generateSearchKeywords(brand));

    bool isHalal;
    String? nonHalalReason;

    // If manual status is provided, use it
    if (manualIsHalal != null) {
      isHalal = manualIsHalal;
      nonHalalReason = !manualIsHalal ? manualNonHalalReason : null;
    } else {
      // Analyze ingredients for halal status
      final analyzedIngredients = await _ingredientAnalyzer.analyzeIngredients(ingredients);
      isHalal = true;
      List<String> concerns = [];

      for (var (ingredient, isIngredientHalal, reason) in analyzedIngredients) {
        if (!isIngredientHalal) {
          isHalal = false;
          if (reason != null) {
            concerns.add('$ingredient: $reason');
          }
        }
      }
      
      nonHalalReason = concerns.isNotEmpty ? concerns.join('\n') : null;
    }

    // Create product document
    await _firestore.collection(collection).add({
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'description': '', // Default empty description
      'category': '', // Default empty category
      'manufacturer': brand, // Use brand as manufacturer for now
      'ingredients': ingredients,
      'searchKeywords': searchKeywords,
      'isHalal': isHalal,
      'nonHalalReason': nonHalalReason,
      'imageUrl': imageUrl,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get product by ID
  Future<Product?> getProduct(String id) async {
    final doc = await _firestore.collection(collection).doc(id).get();
    if (doc.exists) {
      return Product.fromFirestore(doc);
    }
    return null;
  }

  // Update product
  Future<void> updateProduct(Product product) async {
    // Generate search keywords
    final List<String> searchKeywords = Product.generateSearchKeywords(product.name);
    searchKeywords.addAll(Product.generateSearchKeywords(product.manufacturer));
    
    await _firestore.collection(collection).doc(product.id).update({
      ...product.toFirestore(),
      'searchKeywords': searchKeywords,
    });
  }

  // Delete product
  Future<void> deleteProduct(String id) async {
    await _firestore.collection(collection).doc(id).delete();
  }

  // Get product by barcode
  Future<Product?> getProductByBarcode(String barcode) async {
    final snapshot = await _firestore
        .collection(collection)
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Product.fromFirestore(snapshot.docs.first);
  }

  // Update product fields
  Future<void> updateProductFields(String id, {
    String? name,
    String? brand,
    List<String>? ingredients,
    String? imageUrl,
  }) async {
    final updates = <String, dynamic>{};
    
    if (name != null) updates['name'] = name;
    if (brand != null) updates['brand'] = brand;
    if (imageUrl != null) updates['imageUrl'] = imageUrl;
    
    // If ingredients are updated, re-analyze them
    if (ingredients != null) {
      final analyzedIngredients = await _ingredientAnalyzer.analyzeIngredients(ingredients);
      
      bool isHalal = true;
      List<String> concerns = [];
      
      for (var (ingredient, isIngredientHalal, reason) in analyzedIngredients) {
        if (!isIngredientHalal) {
          isHalal = false;
          if (reason != null) {
            concerns.add('$ingredient: $reason');
          }
        }
      }
      
      updates['ingredients'] = ingredients;
      updates['isHalal'] = isHalal;
      updates['nonHalalReason'] = concerns.isNotEmpty ? concerns.join('\n') : null;
    }

    if (updates.isNotEmpty) {
      await _firestore.collection(collection).doc(id).update(updates);
    }
  }

  // Get all products
  Stream<List<Product>> getProducts() {
    return _firestore
        .collection(collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
  }

  // Get user's products
  Stream<List<Product>> getUserProducts() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection(collection)
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
  }
} 