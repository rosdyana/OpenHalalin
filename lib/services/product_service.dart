import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:halalapp/models/product.dart';
import 'package:halalapp/services/ingredient_analyzer_service.dart';
import 'package:halalapp/services/translation_service.dart';

class ProductService {
  final _productsCollection = FirebaseFirestore.instance.collection('products');
  final _ingredientAnalyzer = IngredientAnalyzerService();

  Future<Product?> getProductByBarcode(String barcode) async {
    final snapshot = await _productsCollection
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return Product.fromMap({
      'id': snapshot.docs.first.id,
      ...snapshot.docs.first.data(),
    });
  }

  Future<void> addProduct(String barcode, String name, String brand, List<String> ingredients, String? imageUrl) async {
    // First, analyze all ingredients
    final analyzedIngredients = await _ingredientAnalyzer.analyzeIngredients(ingredients);
    
    // If any ingredient is non-halal, the product is non-halal
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

    final product = Product(
      id: _productsCollection.doc().id,
      barcode: barcode,
      name: name,
      brand: brand,
      ingredients: ingredients,
      imageUrl: imageUrl,
      isHalal: isHalal,
      nonHalalReason: concerns.isNotEmpty ? concerns.join('\n') : null,
      createdAt: DateTime.now(),
      createdBy: FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
    );

    await _productsCollection.doc(product.id).set(product.toMap());
  }

  Future<void> updateProduct(String id, {
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
      await _productsCollection.doc(id).update(updates);
    }
  }

  Stream<List<Product>> getProducts() {
    return _productsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromMap({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  Stream<List<Product>> getUserProducts() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _productsCollection
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromMap({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  Future<void> deleteProduct(String productId) async {
    await _productsCollection.doc(productId).delete();
  }
} 