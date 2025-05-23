import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Restaurant> favoriteRestaurants = [];
  bool isLoading = true;
  Set<String> _favoriteRestaurantIds = {};

  @override
  void initState() {
    super.initState();
    _loadFavoriteRestaurants();
  }

  Future<void> _loadFavoriteRestaurants() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final List<String> favoriteRestaurantIds =
        List<String>.from(doc.data()?['favoriteRestaurants'] ?? []);
    final restaurantsSnapshot =
        await FirebaseFirestore.instance.collection('restaurants').get();
    List<Restaurant> restaurants = [];
    for (final restaurantDoc in restaurantsSnapshot.docs) {
      if (favoriteRestaurantIds.contains(restaurantDoc.id)) {
        final menuSnapshot =
            await restaurantDoc.reference.collection('menu').get();
        final menu = menuSnapshot.docs
            .map((item) => MenuItem.fromMap(item.id, item.data()))
            .toList();
        restaurants.add(
            Restaurant.fromMap(restaurantDoc.id, restaurantDoc.data(), menu));
      }
    }
    setState(() {
      favoriteRestaurants = restaurants;
      isLoading = false;
      _favoriteRestaurantIds = Set<String>.from(favoriteRestaurantIds);
    });
  }

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
          'Избранные рестораны',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : favoriteRestaurants.isEmpty
              ? Center(
                  child: Text(
                    'Избранных ресторанов пока нет',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: favoriteRestaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = favoriteRestaurants[index];
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
                ),
    );
  }
}

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
