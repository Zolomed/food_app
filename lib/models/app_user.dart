class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final List<String> favorites; // Устарело, можно удалить позже
  final List<Map<String, dynamic>> cart;
  final List<String> allergies;
  final bool hideAllergenFoods;
  final List<Map<String, dynamic>> addresses;
  final String? selectedAddressId;

  // Новые поля для избранного
  final List<String> favoriteRestaurants;
  final Map<String, List<String>> favoriteMenus;

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
    this.favoriteRestaurants = const [],
    this.favoriteMenus = const {},
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
      'favoriteRestaurants': favoriteRestaurants,
      'favoriteMenus': favoriteMenus,
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
      favoriteRestaurants: List<String>.from(map['favoriteRestaurants'] ?? []),
      favoriteMenus: map['favoriteMenus'] != null
          ? Map<String, List<String>>.from(
              (map['favoriteMenus'] as Map).map(
                (key, value) => MapEntry(
                  key as String,
                  List<String>.from(value as List),
                ),
              ),
            )
          : {},
    );
  }
}
