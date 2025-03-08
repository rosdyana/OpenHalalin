import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:halalapp/models/ingredient.dart';

class IngredientService {
  final _ingredientsCollection = FirebaseFirestore.instance.collection('ingredients');

  // Get ingredient by English name
  Future<Ingredient?> getIngredientByEnglishName(String name) async {
    final snapshot = await _ingredientsCollection
        .where('englishName', isEqualTo: name.toLowerCase())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return Ingredient.fromMap({
      'id': snapshot.docs.first.id,
      ...snapshot.docs.first.data(),
    });
  }

  // Search ingredients by name in any language
  Future<List<Ingredient>> searchIngredients(String query, String languageCode) async {
    // First, try to find by exact match in the specified language
    final snapshot = await _ingredientsCollection
        .where('translations.$languageCode', isEqualTo: query.toLowerCase())
        .limit(10)
        .get();

    List<Ingredient> results = snapshot.docs
        .map((doc) => Ingredient.fromMap({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();

    // If no results, try partial match on English name
    if (results.isEmpty) {
      final englishSnapshot = await _ingredientsCollection
          .where('englishName', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('englishName', isLessThan: query.toLowerCase() + 'z')
          .limit(10)
          .get();

      results = englishSnapshot.docs
          .map((doc) => Ingredient.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    }

    return results;
  }

  // Add new ingredient
  Future<void> addIngredient(String name, String languageCode, bool isHalal,
      {String? nonHalalReason}) async {
    
    // Create translations map
    Map<String, String> translations = {
      languageCode: name.toLowerCase(),
    };

    // Create new ingredient
    final ingredient = Ingredient(
      id: _ingredientsCollection.doc().id,
      translations: translations,
      englishName: name.toLowerCase(),
      isHalal: isHalal,
      nonHalalReason: nonHalalReason,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      source: 'user',
    );

    await _ingredientsCollection.doc(ingredient.id).set(ingredient.toMap());
  }

  // Update ingredient
  Future<void> updateIngredient(String id,
      {Map<String, String>? translations,
      bool? isHalal,
      String? nonHalalReason}) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (translations != null) updates['translations'] = translations;
    if (isHalal != null) updates['isHalal'] = isHalal;
    if (nonHalalReason != null) updates['nonHalalReason'] = nonHalalReason;

    await _ingredientsCollection.doc(id).update(updates);
  }

  // Delete ingredient
  Future<void> deleteIngredient(String id) async {
    await _ingredientsCollection.doc(id).delete();
  }

  // Get all ingredients
  Stream<List<Ingredient>> getAllIngredients() {
    return _ingredientsCollection
        .orderBy('englishName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Ingredient.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    });
  }
} 