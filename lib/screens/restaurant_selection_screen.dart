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
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              //TODO сделать через бд
              final deliveryTime = '45–55 мин';
              final rating = 4.8;
              final cuisine = 'Русская, Блины, Десерты';
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Картинка ресторана
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: restaurant.image.startsWith('http')
                                  ? Image.network(
                                      restaurant.image,
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      restaurant.image,
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restaurant.name,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.directions_car,
                                      size: 18, color: Colors.grey[700]),
                                  SizedBox(width: 4),
                                  Text(
                                    deliveryTime,
                                    style: TextStyle(
                                        fontSize: 15, color: Colors.black87),
                                  ),
                                  SizedBox(width: 16),
                                  Icon(Icons.star,
                                      size: 18, color: Colors.orange),
                                  SizedBox(width: 4),
                                  Text(
                                    rating.toString(),
                                    style: TextStyle(
                                        fontSize: 15, color: Colors.black87),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                cuisine,
                                style: TextStyle(
                                    color: Colors.black87, fontSize: 15),
                              ),
                              SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
