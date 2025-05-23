import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';

class RestaurantSelectionScreen extends StatefulWidget {
  const RestaurantSelectionScreen({super.key});

  @override
  State<RestaurantSelectionScreen> createState() =>
      _RestaurantSelectionScreenState();
}

class _RestaurantSelectionScreenState extends State<RestaurantSelectionScreen> {
  late Future<List<Restaurant>> _futureRestaurants;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _futureRestaurants = fetchRestaurants();
  }

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
                          return _RestaurantCard(
                            restaurant: restaurant,
                            fixedHeight: cardHeight,
                          );
                        },
                      );
                    } else {
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        itemCount: restaurants.length,
                        itemBuilder: (context, index) {
                          final restaurant = restaurants[index];
                          return _RestaurantCard(
                            restaurant: restaurant,
                            fixedHeight: 300,
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

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final double fixedHeight;
  const _RestaurantCard({
    required this.restaurant,
    required this.fixedHeight,
  });

  @override
  Widget build(BuildContext context) {
    final rating = 4.8;
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
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                                        Text('Рейтинг: $rating'),
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
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.orange),
                            SizedBox(width: 4),
                            Text(
                              rating.toString(),
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
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
