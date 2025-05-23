import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';
import '../widgets/food_card.dart';

class FoodSelectionScreen extends StatefulWidget {
  const FoodSelectionScreen({super.key});

  @override
  _FoodSelectionScreenState createState() => _FoodSelectionScreenState();
}

class _FoodSelectionScreenState extends State<FoodSelectionScreen> {
  Set<String> _favoriteIds = {};
  bool isLoading = true;
  bool _isInit = false;
  String selectedCategory = '';
  List<String> categories = [];
  List<MenuItem> menu = [];
  Restaurant? restaurant;
  Map<String, int> cartQuantities = {};
  List<String> userAllergies = [];
  bool hideAllergenFoods = true;

  String _searchQuery = ''; // Для поиска по блюдам

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _initData();
      _isInit = true;
    }
  }

  Future<void> _initData() async {
    final Restaurant rest =
        ModalRoute.of(context)!.settings.arguments as Restaurant;
    setState(() {
      restaurant = rest;
      menu = rest.menu;
      categories = [
        'Все',
        ...rest.menu.map((e) => e.category ?? 'Без категории').toSet().toList()
      ];
      selectedCategory = categories.isNotEmpty ? categories[0] : '';
      isLoading = false;
    });
    await _loadFavorites();
    await _loadCartQuantities();
    await _loadUserAllergies();
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

  Future<void> _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    setState(() {
      _favoriteIds = Set<String>.from(doc.data()?['favorites'] ?? []);
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

  Future<void> _toggleFavorite(String menuItemId) async {
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
    setState(() {
      _favoriteIds = Set<String>.from(favorites);
    });
  }

  Future<void> addToCart(MenuItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    List cart = List<Map<String, dynamic>>.from(doc.data()?['cart'] ?? []);
    final index = cart.indexWhere((i) => i['menuItemId'] == item.id);

    // --- Проверка ресторана ---
    final String currentRestaurantId = restaurant?.id ?? '';
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

    // Проверка на общее количество
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
        'menuItemId': item.id,
        'name': item.name,
        'price': item.price,
        'image': item.image,
        'weight': item.weight,
        'quantity': 1,
        'restaurantId': currentRestaurantId,
      });
    }
    await docRef.update({'cart': cart});
    await _loadCartQuantities();
  }

  Future<void> removeFromCart(MenuItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    List cart = List<Map<String, dynamic>>.from(doc.data()?['cart'] ?? []);
    final index = cart.indexWhere((i) => i['menuItemId'] == item.id);
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

  int get totalCartCount =>
      cartQuantities.values.fold(0, (sum, qty) => sum + qty);

  void _showFoodDialog(MenuItem item) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    final double minHeight = 500;
    final double maxHeight = 600;
    final double desiredHeight =
        (screenHeight * 0.8).clamp(minHeight, maxHeight);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            minHeight: minHeight,
            maxHeight: desiredHeight,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minHeight,
                maxHeight: desiredHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 16),
                    Container(
                      width: 60,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: item.image.startsWith('http')
                          ? Image.network(
                              item.image,
                              width: screenWidth,
                              height: 220,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              item.image,
                              width: screenWidth,
                              height: 220,
                              fit: BoxFit.cover,
                            ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        item.description ?? '',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if ((item.ingredients ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12),
                        child: Text(
                          item.ingredients!,
                          style: TextStyle(fontSize: 15, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (item.weight != null && item.weight!.isNotEmpty)
                            Text(
                              '${item.weight} г',
                              style: TextStyle(
                                  fontSize: 15, color: Colors.grey[700]),
                            ),
                          if (item.weight != null && item.weight!.isNotEmpty)
                            SizedBox(width: 10),
                          Text(
                            '${item.price} ₽',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;
                            final doc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .get();
                            List cart = List<Map<String, dynamic>>.from(
                                doc.data()?['cart'] ?? []);
                            final String currentRestaurantId =
                                restaurant?.id ?? '';
                            if (cart.isNotEmpty) {
                              final String cartRestaurantId =
                                  cart.first['restaurantId'] ?? '';
                              if (cartRestaurantId != currentRestaurantId) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Можно заказывать только из одного ресторана! Очистьте корзину для нового заказа.')),
                                );
                                return;
                              }
                            }
                            int totalCount = cartQuantities.values
                                .fold(0, (sum, qty) => sum + qty);
                            if (totalCount >= 30) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Максимум 30 блюд в заказе!')),
                              );
                              return;
                            }
                            await addToCart(item);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Text(
                            'Добавить в корзину',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || restaurant == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filteredMenu = menu.where((item) {
      final hasAllergen = item.allergens.any((a) => userAllergies.contains(a));
      final matchesCategory = selectedCategory == 'Все'
          ? true
          : (item.category ?? 'Без категории') == selectedCategory;
      final matchesSearch = _searchQuery.isEmpty
          ? true
          : (item.name.toLowerCase().contains(_searchQuery) ||
              (item.description ?? '').toLowerCase().contains(_searchQuery));
      if (hideAllergenFoods && hasAllergen) return false;
      return matchesCategory && matchesSearch;
    }).toList();

    final int totalCount =
        cartQuantities.values.fold(0, (sum, qty) => sum + qty);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          restaurant!.name,
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск по блюдам',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, idx) {
                final cat = categories[idx];
                final selected = cat == selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = cat;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? Colors.orange : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const minCardWidth = 220.0;
                final crossAxisCount =
                    (constraints.maxWidth / minCardWidth).floor().clamp(1, 6);

                final spacing = 12.0;
                final cardWidth = (constraints.maxWidth -
                        (crossAxisCount - 1) * spacing -
                        20) /
                    crossAxisCount;
                final cardHeight = 380.0;
                final aspectRatio = cardWidth / cardHeight;
                return GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: spacing,
                    childAspectRatio: aspectRatio,
                  ),
                  itemCount: filteredMenu.length,
                  itemBuilder: (context, index) {
                    final item = filteredMenu[index];
                    final isFavorite = _favoriteIds.contains(item.id);
                    final quantity = cartQuantities[item.id] ?? 0;
                    final containsAllergen =
                        item.allergens.any((a) => userAllergies.contains(a));

                    return GestureDetector(
                      onTap: () => _showFoodDialog(item),
                      child: FoodCard(
                        image: item.image,
                        name: item.name,
                        price: item.price.toDouble(),
                        weight: item.weight?.toString(),
                        isFavorite: isFavorite,
                        quantity: quantity,
                        onFavoriteTap: () async {
                          await _toggleFavorite(item.id);
                          setState(() {});
                        },
                        onAdd: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;
                          final doc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .get();
                          List cart = List<Map<String, dynamic>>.from(
                              doc.data()?['cart'] ?? []);
                          final String currentRestaurantId =
                              restaurant?.id ?? '';
                          if (cart.isNotEmpty) {
                            final String cartRestaurantId =
                                cart.first['restaurantId'] ?? '';
                            if (cartRestaurantId != currentRestaurantId) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Можно заказывать только из одного ресторана! Очистьте корзину для нового заказа.')),
                              );
                              return;
                            }
                          }
                          int totalCount = cartQuantities.values
                              .fold(0, (sum, qty) => sum + qty);
                          if (totalCount >= 30) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Максимум 30 блюд в заказе!')),
                            );
                            return;
                          }
                          await addToCart(item);
                          setState(() {});
                        },
                        onRemove: () async {
                          await removeFromCart(item);
                          setState(() {});
                        },
                        allergenWarning: !hideAllergenFoods && containsAllergen,
                        isTotalLimit: totalCount >= 30,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: totalCartCount > 0
          ? SafeArea(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.white,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/payment');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Далее',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
