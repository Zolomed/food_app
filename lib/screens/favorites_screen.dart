import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import '../widgets/restaurant_list.dart';

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
    _loadFavoriteRestaurants(); // Загрузка избранных ресторанов при запуске экрана
  }

  // Загрузка избранных ресторанов пользователя из Firestore
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
          'Избранные рестораны',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : favoriteRestaurants.isEmpty
              // Если нет избранных ресторанов — показать сообщение
              ? Center(
                  child: Text(
                    'Избранных ресторанов пока нет',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              // Использование виджета RestaurantList для отображения избранных ресторанов
              : RestaurantList(
                  restaurants: favoriteRestaurants,
                  favoriteRestaurantIds: _favoriteRestaurantIds,
                  onFavoriteTap: (id) async {
                    await _toggleFavoriteRestaurant(id);
                  },
                  searchQuery: '', // В избранном поиск не нужен
                ),
    );
  }
}
