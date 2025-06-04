import 'package:flutter/material.dart';
import '../models/restaurant.dart';

class RestaurantScreen extends StatelessWidget {
  const RestaurantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем объект ресторана из аргументов маршрута
    final Restaurant restaurant =
        ModalRoute.of(context)!.settings.arguments as Restaurant;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          restaurant.name,
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Картинка ресторана
          restaurant.image.startsWith('http')
              ? Image.network(
                  restaurant.image,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  restaurant.image,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
          // Описание ресторана
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              restaurant.description,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          // Кнопка перехода к выбору блюд
          Expanded(
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/food_selection',
                    arguments: restaurant,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                ),
                child: Text(
                  'Выбрать еду',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
