class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final List<String> favorites;
  final List<Map<String, dynamic>> cart;
  final List<String> allergies;
  final bool hideAllergenFoods;
  final List<Map<String, dynamic>> addresses;
  final String? selectedAddressId;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.favorites = const [],
    this.cart = const [],
    this.allergies = const [],
    this.hideAllergenFoods = true,
    this.addresses = const [],
    this.selectedAddressId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'favorites': favorites,
      'cart': cart,
      'allergies': allergies,
      'hideAllergenFoods': hideAllergenFoods,
      'addresses': addresses,
      'selectedAddressId': selectedAddressId,
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
      allergies: List<String>.from(map['allergies'] ?? []),
      hideAllergenFoods: map['hideAllergenFoods'] ?? true,
      addresses: List<Map<String, dynamic>>.from(map['addresses'] ?? []),
      selectedAddressId: map['selectedAddressId'],
    );
  }
}
