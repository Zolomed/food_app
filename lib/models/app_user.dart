class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final List<String> favorites;
  final List<Map<String, dynamic>> cart;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.favorites = const [],
    this.cart = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'favorites': favorites,
      'cart': cart,
    };
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'],
      favorites: List<String>.from(map['favorites'] ?? []),
      cart: List<Map<String, dynamic>>.from(map['cart'] ?? []),
    );
  }
}
