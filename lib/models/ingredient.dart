class Ingredient {
  final String id;
  final Map<String, String> translations; // Map of language code to translation
  final String englishName; // Default English name
  final bool isHalal;
  final String? nonHalalReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? source; // Source of the ingredient information
  final List<String>? alternativeNames; // Alternative names in English

  Ingredient({
    required this.id,
    required this.translations,
    required this.englishName,
    required this.isHalal,
    this.nonHalalReason,
    required this.createdAt,
    required this.updatedAt,
    this.source,
    this.alternativeNames,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'translations': translations,
      'englishName': englishName,
      'isHalal': isHalal,
      'nonHalalReason': nonHalalReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'source': source,
      'alternativeNames': alternativeNames,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'] as String,
      translations: Map<String, String>.from(map['translations'] as Map),
      englishName: map['englishName'] as String,
      isHalal: map['isHalal'] as bool,
      nonHalalReason: map['nonHalalReason'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      source: map['source'] as String?,
      alternativeNames: map['alternativeNames'] != null
          ? List<String>.from(map['alternativeNames'] as List)
          : null,
    );
  }

  String getTranslation(String languageCode) {
    return translations[languageCode] ?? englishName;
  }
} 