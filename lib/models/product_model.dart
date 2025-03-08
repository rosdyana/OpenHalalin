enum HalalStatus {
  halal,
  haram,
  mushbooh, // doubtful
  unknown
}

class ProductModel {
  final String barcode;
  final String name;
  final String brand;
  final String manufacturer;
  final List<String> ingredients;
  final HalalStatus halalStatus;
  final String? certificationInfo;
  final String? imageUrl;
  final String addedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.manufacturer,
    required this.ingredients,
    required this.halalStatus,
    this.certificationInfo,
    this.imageUrl,
    required this.addedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> data) {
    return ProductModel(
      barcode: data['barcode'] ?? '',
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      manufacturer: data['manufacturer'] ?? '',
      ingredients: List<String>.from(data['ingredients'] ?? []),
      halalStatus: HalalStatus.values.firstWhere(
        (e) => e.toString() == 'HalalStatus.${data['halalStatus']}',
        orElse: () => HalalStatus.unknown,
      ),
      certificationInfo: data['certificationInfo'],
      imageUrl: data['imageUrl'],
      addedBy: data['addedBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'manufacturer': manufacturer,
      'ingredients': ingredients,
      'halalStatus': halalStatus.toString().split('.').last,
      'certificationInfo': certificationInfo,
      'imageUrl': imageUrl,
      'addedBy': addedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  ProductModel copyWith({
    String? barcode,
    String? name,
    String? brand,
    String? manufacturer,
    List<String>? ingredients,
    HalalStatus? halalStatus,
    String? certificationInfo,
    String? imageUrl,
    String? addedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      manufacturer: manufacturer ?? this.manufacturer,
      ingredients: ingredients ?? this.ingredients,
      halalStatus: halalStatus ?? this.halalStatus,
      certificationInfo: certificationInfo ?? this.certificationInfo,
      imageUrl: imageUrl ?? this.imageUrl,
      addedBy: addedBy ?? this.addedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 