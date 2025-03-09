import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:halalapp/models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'products';

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
    String? halalCertificateUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User must be logged in to add products');

    // Generate search keywords
    final List<String> searchKeywords = Product.generateSearchKeywords(name);
    searchKeywords.addAll(Product.generateSearchKeywords(brand));

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
      'isHalal': manualIsHalal ?? true, // Default to true unless specified
      'nonHalalReason': manualNonHalalReason,
      'imageUrl': imageUrl,
      'halalCertificateUrl': halalCertificateUrl,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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

  // Get product by ID
  Future<Product?> getProductById(String id) async {
    final doc = await _firestore.collection(collection).doc(id).get();
    if (!doc.exists) return null;
    return Product.fromFirestore(doc);
  }

  // Get user's scanned products
  Stream<List<Product>> getUserScannedProducts(String userId) {
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
