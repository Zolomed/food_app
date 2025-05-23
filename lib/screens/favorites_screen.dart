import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_app/widgets/food_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> favoriteItems = [];
  Map<String, int> cartQuantities = {};
  bool isLoading = true;
  List<String> userAllergies = [];
  bool hideAllergenFoods = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadCartQuantities();
    _loadUserAllergies();
  }

  Future<void> _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final List<String> favoriteIds =
        List<String>.from(doc.data()?['favorites'] ?? []);
    List<Map<String, dynamic>> items = [];
    final restaurantsSnapshot =
        await FirebaseFirestore.instance.collection('restaurants').get();
    for (final restaurantDoc in restaurantsSnapshot.docs) {
      final menuSnapshot =
          await restaurantDoc.reference.collection('menu').get();
      for (final menuItemDoc in menuSnapshot.docs) {
        if (favoriteIds.contains(menuItemDoc.id)) {
          final data = menuItemDoc.data();
          data['menuItemId'] = menuItemDoc.id;
          data['restaurantId'] = restaurantDoc.id;
          items.add(data);
        }
      }
    }
    setState(() {
      favoriteItems = items;
      isLoading = false;
    });
  }

  Future<void> _loadCartQuantities() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final List cart =
        List<Map<String, dynamic>>.from(doc.data()?['cart'] ?? []);
    final Map<String, int> map = {};
    for (var item in cart) {
      map[item['menuItemId']] = item['quantity'];
    }
    setState(() {
      cartQuantities = map;
    });
  }

  Future<void> _loadUserAllergies() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    setState(() {
      userAllergies = List<String>.from(doc.data()?['allergies'] ?? []);
      hideAllergenFoods = doc.data()?['hideAllergenFoods'] ?? true;
    });
  }

  Future<void> toggleFavorite(String menuItemId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    List favorites = List<String>.from(doc.data()?['favorites'] ?? []);
    if (favorites.contains(menuItemId)) {
      favorites.remove(menuItemId);
    } else {
      favorites.add(menuItemId);
    }
    await docRef.update({'favorites': favorites});
    await _loadFavorites();
  }

  Future<void> addToCart(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    List cart = List<Map<String, dynamic>>.from(doc.data()?['cart'] ?? []);
    final index = cart.indexWhere((i) => i['menuItemId'] == item['menuItemId']);

    // --- Проверка ресторана ---
    final String currentRestaurantId = item['restaurantId'] ?? '';
    if (cart.isNotEmpty) {
      final String cartRestaurantId = cart.first['restaurantId'] ?? '';
      if (cartRestaurantId != currentRestaurantId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Можно заказывать только из одного ресторана! Очистьте корзину для нового заказа.')),
        );
        return;
      }
    }
    // --- Конец проверки ресторана ---

    int totalCount =
        cart.fold<int>(0, (sum, i) => sum + (i['quantity'] as int));
    if (totalCount >= 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Максимум 30 блюд в заказе!')),
      );
      return;
    }

    if (index >= 0) {
      cart[index]['quantity'] += 1;
    } else {
      cart.add({
        'menuItemId': item['menuItemId'],
        'name': item['name'],
        'price': item['price'],
        'image': item['image'],
        'weight': item['weight'],
        'quantity': 1,
        'restaurantId': currentRestaurantId,
      });
    }
    await docRef.update({'cart': cart});
    await _loadCartQuantities();
  }

  Future<void> removeFromCart(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    List cart = List<Map<String, dynamic>>.from(doc.data()?['cart'] ?? []);
    final index = cart.indexWhere((i) => i['menuItemId'] == item['menuItemId']);
    if (index >= 0) {
      if (cart[index]['quantity'] > 1) {
        cart[index]['quantity'] -= 1;
      } else {
        cart.removeAt(index);
      }
      await docRef.update({'cart': cart});
      await _loadCartQuantities();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Избранное',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : favoriteItems.isEmpty
              ? Center(
                  child: Text(
                    'Избранных блюд пока нет',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    const minCardWidth = 220.0;
                    final crossAxisCount = (constraints.maxWidth / minCardWidth)
                        .floor()
                        .clamp(1, 6);
                    final spacing = 12.0;
                    final cardWidth = (constraints.maxWidth -
                            (crossAxisCount - 1) * spacing -
                            20) /
                        crossAxisCount;
                    final cardHeight = 380.0;
                    final aspectRatio = cardWidth / cardHeight;

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 18,
                        crossAxisSpacing: spacing,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: favoriteItems.length,
                      itemBuilder: (context, index) {
                        final item = favoriteItems[index];
                        final quantity =
                            cartQuantities[item['menuItemId']] ?? 0;
                        final List allergens = item['allergens'] ?? [];
                        final containsAllergen =
                            allergens.any((a) => userAllergies.contains(a));
                        if (hideAllergenFoods && containsAllergen) {
                          return const SizedBox.shrink();
                        }
                        return FoodCard(
                          image: item['image'] ?? '',
                          name: item['name'] ?? '',
                          price: (item['price'] is int)
                              ? (item['price'] as int).toDouble()
                              : (item['price'] ?? 0.0),
                          weight: item['weight']?.toString(),
                          isFavorite: true,
                          quantity: quantity,
                          onFavoriteTap: () async {
                            await toggleFavorite(item['menuItemId']);
                            setState(() {});
                          },
                          onAdd: () async {
                            await addToCart(item);
                            setState(() {});
                          },
                          onRemove: () async {
                            await removeFromCart(item);
                            setState(() {});
                          },
                          allergenWarning:
                              !hideAllergenFoods && containsAllergen,
                          isTotalLimit: cartQuantities.values
                                  .fold(0, (sum, qty) => sum + qty) >=
                              30,
                        );
                      },
                    );
                  },
                ),
    );
  }
}
