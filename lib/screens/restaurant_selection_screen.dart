import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';

class RestaurantSelectionScreen extends StatelessWidget {
  const RestaurantSelectionScreen({super.key});

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
      body: FutureBuilder<List<Restaurant>>(
        future: fetchRestaurants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Нет доступных ресторанов'));
          }
          final restaurants = snapshot.data!;

          return LayoutBuilder(
            builder: (context, constraints) {
              // Если ширина экрана больше 700 — показываем сетку, иначе список
              if (constraints.maxWidth > 700) {
                // Сетка для web/desktop
                const minCardWidth = 340.0;
                final crossAxisCount =
                    (constraints.maxWidth / minCardWidth).floor().clamp(2, 6);
                final spacing = 24.0;
                final cardWidth = (constraints.maxWidth -
                        (crossAxisCount - 1) * spacing -
                        32) /
                    crossAxisCount;
                final cardHeight = 260.0;
                final aspectRatio = cardWidth / cardHeight;

                return GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: aspectRatio,
                  ),
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = restaurants[index];
                    // Используйте тот же виджет карточки, что и в ListView, только с фиксированной высотой
                    return _RestaurantCard(restaurant: restaurant);
                  },
                );
              } else {
                // Список для мобильных
                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = restaurants[index];
                    return _RestaurantCard(restaurant: restaurant);
                  },
                );
              }
            },
          );
        },
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  const _RestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    // TODO: Подставьте реальные значения времени, рейтинга и кухни из restaurant
    final deliveryTime = '45–55 мин';
    final rating = 4.8;
    final cuisine = 'Русская, Блины, Десерты';

    return LayoutBuilder(
      builder: (context, constraints) {
        // Ограничиваем высоту карточки только для сетки (широкий экран)
        final isWide = constraints.maxWidth > 400;
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
              child: ConstrainedBox(
                constraints: isWide
                    ? BoxConstraints(
                        minHeight: 260, // минимальная высота для сетки
                        maxHeight: 260, // максимальная высота для сетки
                      )
                    : BoxConstraints(), // без ограничений для списка
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurant.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.directions_car,
                                  size: 16, color: Colors.grey[700]),
                              SizedBox(width: 4),
                              Text(
                                deliveryTime,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black87),
                              ),
                              SizedBox(width: 12),
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
                            style:
                                TextStyle(color: Colors.black87, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
