import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> favoriteItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
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
    // Получаем блюда по id из всех ресторанов
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
    _loadFavorites();
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
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10.0),
                  itemCount: favoriteItems.length,
                  itemBuilder: (context, index) {
                    final item = favoriteItems[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: item['image'] != null &&
                                    item['image'].toString().startsWith('http')
                                ? Image.network(
                                    item['image'],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    item['image'] ?? '',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '${item['price']} р.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.favorite, color: Colors.red),
                            onPressed: () async {
                              await toggleFavorite(item['menuItemId']);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
