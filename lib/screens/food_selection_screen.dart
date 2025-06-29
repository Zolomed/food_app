import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_app/widgets/food_detail_bottom_sheet.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';
import '../widgets/food_card.dart';

class FoodSelectionScreen extends StatefulWidget {
  const FoodSelectionScreen({super.key});

  @override
  _FoodSelectionScreenState createState() => _FoodSelectionScreenState();
}

class _FoodSelectionScreenState extends State<FoodSelectionScreen> {
  Set<String> _favoriteMenuIds = {};
  bool isLoading = true;
  bool _isInit = false;
  String selectedCategory = '';
  List<String> categories = [];
  List<MenuItem> menu = [];
  Restaurant? restaurant;
  Map<String, int> cartQuantities = {};
  List<String> userAllergies = [];
  bool hideAllergenFoods = true;
  bool isRestaurantFavorite = false;

  String _searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _initData(); // Инициализация данных при первом открытии экрана
      _isInit = true;
    }
  }

  // Загрузка данных ресторана, меню, категорий и пользовательских настроек
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
    await _loadFavoriteMenu();
    await _loadCartQuantities();
    await _loadUserAllergies();
    await _loadFavoriteRestaurant();
  }

  // Загрузка аллергий пользователя и настройки скрытия аллергенных блюд
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

  // Загрузка избранных блюд пользователя для текущего ресторана
  Future<void> _loadFavoriteMenu() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || restaurant == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final Map<String, dynamic> favoriteMenus =
        Map<String, dynamic>.from(doc.data()?['favoriteMenus'] ?? {});
    final Set<String> menuIds =
        Set<String>.from(favoriteMenus[restaurant!.id] ?? []);
    setState(() {
      _favoriteMenuIds = menuIds;
    });
  }

  // Добавление или удаление блюда из избранного
  Future<void> _toggleFavoriteMenu(String menuItemId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || restaurant == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    Map<String, dynamic> favoriteMenus =
        Map<String, dynamic>.from(doc.data()?['favoriteMenus'] ?? {});
    List<String> menuIds =
        List<String>.from(favoriteMenus[restaurant!.id] ?? []);
    if (menuIds.contains(menuItemId)) {
      menuIds.remove(menuItemId);
    } else {
      menuIds.add(menuItemId);
    }
    favoriteMenus[restaurant!.id] = menuIds;
    await docRef.update({'favoriteMenus': favoriteMenus});
    await _loadFavoriteMenu();
  }

  // Загрузка информации о том, добавлен ли ресторан в избранное
  Future<void> _loadFavoriteRestaurant() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || restaurant == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final List<String> favoriteRestaurants =
        List<String>.from(doc.data()?['favoriteRestaurants'] ?? []);
    setState(() {
      isRestaurantFavorite = favoriteRestaurants.contains(restaurant!.id);
    });
  }

  // Добавление или удаление ресторана из избранного
  Future<void> _toggleFavoriteRestaurant() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || restaurant == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    List<String> favoriteRestaurants =
        List<String>.from(doc.data()?['favoriteRestaurants'] ?? []);
    if (favoriteRestaurants.contains(restaurant!.id)) {
      favoriteRestaurants.remove(restaurant!.id);
    } else {
      favoriteRestaurants.add(restaurant!.id);
    }
    await docRef.update({'favoriteRestaurants': favoriteRestaurants});
    setState(() {
      isRestaurantFavorite = favoriteRestaurants.contains(restaurant!.id);
    });
  }

  // Загрузка количества каждого блюда в корзине пользователя
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

  // Добавление блюда в корзину пользователя
  Future<void> addToCart(MenuItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    List cart = List<Map<String, dynamic>>.from(doc.data()?['cart'] ?? []);
    final index = cart.indexWhere((i) => i['menuItemId'] == item.id);

    final String currentRestaurantId = restaurant?.id ?? '';
    if (cart.isNotEmpty) {
      final String cartRestaurantId = cart.first['restaurantId'] ?? '';
      // Проверка: можно заказывать только из одного ресторана
      if (cartRestaurantId != currentRestaurantId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Можно заказывать только из одного ресторана! Очистьте корзину для нового заказа.')),
        );
        return;
      }
    }

    int totalCount =
        cart.fold<int>(0, (sum, i) => sum + (i['quantity'] as int));
    // Проверка на максимальное количество блюд
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

  // Удаление блюда из корзины пользователя
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

  // Общее количество блюд в корзине
  int get totalCartCount =>
      cartQuantities.values.fold(0, (sum, qty) => sum + qty);

  // Открытие подробного диалога по блюду
  void _showFoodDialog(MenuItem item) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    final double minHeight = 500;
    final double maxHeight = 600;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FoodDetailBottomSheet(
          item: item,
          screenWidth: screenWidth,
          minHeight: minHeight,
          maxHeight: maxHeight,
          onAddToCart: () async {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) return;
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
            List cart =
                List<Map<String, dynamic>>.from(doc.data()?['cart'] ?? []);
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
            int totalCount =
                cartQuantities.values.fold(0, (sum, qty) => sum + qty);
            if (totalCount >= 30) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Максимум 30 блюд в заказе!')),
              );
              return;
            }
            await addToCart(item);
            Navigator.pop(ctx);
          },
          userAllergies: userAllergies,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || restaurant == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Формирование списка категорий для фильтрации
    final List<String> displayCategories = [
      'Все',
      'Избранное',
      ...categories.where((c) => c != 'Все' && c != 'Избранное')
    ];

    // Фильтрация меню по категории, поиску и аллергенам
    final filteredMenu = menu.where((item) {
      final hasAllergen = item.allergens.any((a) => userAllergies.contains(a));
      bool matchesCategory;
      if (selectedCategory == 'Все') {
        matchesCategory = true;
      } else if (selectedCategory == 'Избранное') {
        matchesCategory = _favoriteMenuIds.contains(item.id);
      } else {
        matchesCategory =
            (item.category ?? 'Без категории') == selectedCategory;
      }
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                restaurant!.name,
                style: TextStyle(color: Colors.black),
              ),
            ),
            // Кнопка "избранное" для ресторана
            IconButton(
              icon: Icon(
                isRestaurantFavorite ? Icons.favorite : Icons.favorite_border,
                color: isRestaurantFavorite ? Colors.red : Colors.grey,
              ),
              tooltip: isRestaurantFavorite
                  ? 'Убрать ресторан из избранного'
                  : 'Добавить ресторан в избранное',
              onPressed: _toggleFavoriteRestaurant,
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Поле поиска по блюдам
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
          // Список категорий для фильтрации
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: displayCategories.length,
              itemBuilder: (context, idx) {
                final cat = displayCategories[idx];
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
          // Сетка блюд
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

                // Адаптивная высота карточки
                final cardHeight = cardWidth * 1.7;
                final clampedCardHeight = cardHeight.clamp(325.0, 360.0);
                final aspectRatio = cardWidth / clampedCardHeight;

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
                    final isFavorite = _favoriteMenuIds.contains(item.id);
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
                          await _toggleFavoriteMenu(item.id);
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
      // Кнопка перехода к оплате, если корзина не пуста
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
