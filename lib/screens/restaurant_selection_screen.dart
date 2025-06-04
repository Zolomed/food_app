import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RestaurantSelectionScreen extends StatefulWidget {
  const RestaurantSelectionScreen({super.key});

  @override
  State<RestaurantSelectionScreen> createState() =>
      _RestaurantSelectionScreenState();
}

class _RestaurantSelectionScreenState extends State<RestaurantSelectionScreen> {
  late Future<List<Restaurant>> _futureRestaurants;
  String _searchQuery = '';
  Set<String> _favoriteRestaurantIds = {};

  @override
  void initState() {
    super.initState();
    _futureRestaurants = fetchRestaurants(); // Загрузка ресторанов из Firestore
    _loadFavoriteRestaurants(); // Загрузка избранных ресторанов пользователя
  }

  // Получение списка ресторанов с меню из Firestore
  Future<List<Restaurant>> fetchRestaurants() async {
    final restaurantsSnapshot =
        await FirebaseFirestore.instance.collection('restaurants').get();
    List<Restaurant> restaurants = [];
    for (var doc in restaurantsSnapshot.docs) {
      final menuSnapshot = await doc.reference.collection('menu').get();
      final menu = menuSnapshot.docs
          .map((item) => MenuItem.fromMap(item.id, item.data()))
          .toList();
      restaurants.add(Restaurant.fromMap(doc.id, doc.data(), menu));
    }
    return restaurants;
  }

  // Загрузка id избранных ресторанов пользователя
  Future<void> _loadFavoriteRestaurants() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    setState(() {
      _favoriteRestaurantIds =
          Set<String>.from(doc.data()?['favoriteRestaurants'] ?? []);
    });
  }

  // Добавление или удаление ресторана из избранного
  Future<void> _toggleFavoriteRestaurant(String restaurantId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    List<String> favoriteRestaurants =
        List<String>.from(doc.data()?['favoriteRestaurants'] ?? []);
    if (favoriteRestaurants.contains(restaurantId)) {
      favoriteRestaurants.remove(restaurantId);
    } else {
      favoriteRestaurants.add(restaurantId);
    }
    await docRef.update({'favoriteRestaurants': favoriteRestaurants});
    await _loadFavoriteRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Выбор ресторана',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Поле поиска по ресторанам
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск по ресторанам',
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
          // Список ресторанов (сетка или список)
          Expanded(
            child: FutureBuilder<List<Restaurant>>(
              future: _futureRestaurants,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Нет доступных ресторанов'));
                }
                final allRestaurants = snapshot.data!;
                final restaurants = _searchQuery.isEmpty
                    ? allRestaurants
                    : allRestaurants
                        .where((r) =>
                            r.name.toLowerCase().contains(_searchQuery) ||
                            r.cuisine.toLowerCase().contains(_searchQuery))
                        .toList();

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 700) {
                      // Сетка ресторанов для широких экранов
                      const minCardWidth = 340.0;
                      final crossAxisCount =
                          (constraints.maxWidth / minCardWidth)
                              .floor()
                              .clamp(2, 6);
                      final spacing = 24.0;
                      final cardWidth = (constraints.maxWidth -
                              (crossAxisCount - 1) * spacing -
                              32) /
                          crossAxisCount;
                      final cardHeight = 300.0;
                      final aspectRatio = cardWidth / cardHeight;

                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          childAspectRatio: aspectRatio,
                        ),
                        itemCount: restaurants.length,
                        itemBuilder: (context, index) {
                          final restaurant = restaurants[index];
                          final isFavorite =
                              _favoriteRestaurantIds.contains(restaurant.id);
                          return _RestaurantCard(
                            restaurant: restaurant,
                            fixedHeight: cardHeight,
                            isFavorite: isFavorite,
                            onFavoriteTap: () async {
                              await _toggleFavoriteRestaurant(restaurant.id);
                            },
                          );
                        },
                      );
                    } else {
                      // Список ресторанов для мобильных устройств
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        itemCount: restaurants.length,
                        itemBuilder: (context, index) {
                          final restaurant = restaurants[index];
                          final isFavorite =
                              _favoriteRestaurantIds.contains(restaurant.id);
                          return _RestaurantCard(
                            restaurant: restaurant,
                            fixedHeight: 250,
                            isFavorite: isFavorite,
                            onFavoriteTap: () async {
                              await _toggleFavoriteRestaurant(restaurant.id);
                            },
                          );
                        },
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Карточка ресторана для отображения в списке/сетке
class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final double fixedHeight;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  const _RestaurantCard({
    required this.restaurant,
    required this.fixedHeight,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final cuisine =
        restaurant.cuisine.isNotEmpty ? restaurant.cuisine : 'Не указано';

    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            // Переход к экрану выбора блюд ресторана
            Navigator.pushNamed(
              context,
              '/food_selection',
              arguments: restaurant,
            );
          },
          child: SizedBox(
            height: fixedHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    // Картинка ресторана
                    ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                      child: restaurant.image.startsWith('http')
                          ? Image.network(
                              restaurant.image,
                              width: double.infinity,
                              height: 140,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              restaurant.image,
                              width: double.infinity,
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                    ),
                    // Кнопка "избранное"
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                          size: 28,
                        ),
                        tooltip: isFavorite
                            ? 'Убрать ресторан из избранного'
                            : 'Добавить ресторан в избранное',
                        onPressed: onFavoriteTap,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Название ресторана
                            Expanded(
                              child: Text(
                                restaurant.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Кнопка информации о ресторане
                            IconButton(
                              icon: Icon(Icons.info_outline,
                                  color: Colors.orange),
                              tooltip: 'Информация о ресторане',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(restaurant.name),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (restaurant.description.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8.0),
                                            child: Text(
                                              restaurant.description,
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          ),
                                        Text('Кухня: $cuisine'),
                                        SizedBox(height: 4),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text('Закрыть'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        // Тип кухни ресторана
                        Text(
                          cuisine,
                          style: TextStyle(color: Colors.black87, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
