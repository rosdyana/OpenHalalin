class Product {
  final String id;
  final String barcode;
  final String name;
  final String brand;
  final List<String> ingredients;
  final String? imageUrl;
  final bool isHalal;
  final String? nonHalalReason;
  final DateTime createdAt;
  final String createdBy;

  Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.brand,
    required this.ingredients,
    this.imageUrl,
    required this.isHalal,
    this.nonHalalReason,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'ingredients': ingredients,
      'imageUrl': imageUrl,
      'isHalal': isHalal,
      'nonHalalReason': nonHalalReason,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      barcode: map['barcode'] as String,
      name: map['name'] as String,
      brand: map['brand'] as String,
      ingredients: List<String>.from(map['ingredients']),
      imageUrl: map['imageUrl'] as String?,
      isHalal: map['isHalal'] as bool,
      nonHalalReason: map['nonHalalReason'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      createdBy: map['createdBy'] as String,
    );
  }
} 