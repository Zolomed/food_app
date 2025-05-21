import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';

//TODO Сделать сортировку блюд
//TODO реализовать правильные переходы
//TODO сделать открытие блюд

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
      categories =
          rest.menu.map((e) => e.category ?? 'Без категории').toSet().toList();
      selectedCategory = categories.isNotEmpty ? categories[0] : '';
      isLoading = false;
    });
    await _loadFavorites();
    await _loadCartQuantities();
    await _loadUserAllergies(); // загрузить аллергии
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

  @override
  Widget build(BuildContext context) {
    if (isLoading || restaurant == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filteredMenu = menu.where((item) {
      final hasAllergen = item.allergens.any((a) => userAllergies.contains(a));
      if (hideAllergenFoods) {
        return !hasAllergen &&
            (item.category ?? 'Без категории') == selectedCategory;
      } else {
        return (item.category ?? 'Без категории') == selectedCategory;
      }
    }).toList();

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
          // Категории
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
          // Сетка карточек еды
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 12,
                childAspectRatio: 0.60,
              ),
              itemCount: filteredMenu.length,
              itemBuilder: (context, index) {
                final item = filteredMenu[index];
                final isFavorite = _favoriteIds.contains(item.id);
                final quantity = cartQuantities[item.id] ?? 0;
                final containsAllergen =
                    item.allergens.any((a) => userAllergies.contains(a));

                return Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF8F7F5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Картинка + сердечко
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 12, right: 12, top: 12, bottom: 0),
                        child: Stack(
                          children: [
                            Center(
                              // Центрируем картинку
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: item.image.startsWith('http')
                                    ? Image.network(
                                        item.image,
                                        height: 110,
                                        fit: BoxFit.contain,
                                      )
                                    : Image.asset(
                                        item.image,
                                        height: 110,
                                        fit: BoxFit.contain,
                                      ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () async {
                                  await _toggleFavorite(item.id);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.85),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color:
                                        isFavorite ? Colors.red : Colors.grey,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${item.price.toStringAsFixed(2)}₽',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          [if (item.weight != null) '${item.weight} г']
                              .join(' · '),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      if (!hideAllergenFoods && containsAllergen)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 2),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Содержит ваш аллерген',
                                style:
                                    TextStyle(color: Colors.red, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      Expanded(child: SizedBox()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: quantity > 0
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove_circle_outline),
                                    onPressed: () async {
                                      await removeFromCart(item);
                                      setState(() {});
                                    },
                                  ),
                                  Text(
                                    '$quantity',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.add_circle_outline),
                                    onPressed: () async {
                                      await addToCart(item);
                                      setState(() {});
                                    },
                                  ),
                                ],
                              )
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await addToCart(item);
                                    setState(() {});
                                  },
                                  icon: Icon(Icons.add, color: Colors.black),
                                  label: Text(
                                    'Добавить',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    side: BorderSide(
                                        color: Colors.black12, width: 1),
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
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
