class UserModel {
  final String uid;
  final String email;
  final String? name;
  final String? photoUrl;
  final List<String> scannedProducts;
  final List<String> savedProducts;

  UserModel({
    required this.uid,
    required this.email,
    this.name,
    this.photoUrl,
    this.scannedProducts = const [],
    this.savedProducts = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'],
      photoUrl: data['photoUrl'],
      scannedProducts: List<String>.from(data['scannedProducts'] ?? []),
      savedProducts: List<String>.from(data['savedProducts'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'scannedProducts': scannedProducts,
      'savedProducts': savedProducts,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? photoUrl,
    List<String>? scannedProducts,
    List<String>? savedProducts,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      scannedProducts: scannedProducts ?? this.scannedProducts,
      savedProducts: savedProducts ?? this.savedProducts,
    );
  }
} 