import 'package:flutter/material.dart';

//TODO сделать бд

class RestaurantSelectionScreen extends StatelessWidget {
  final List<Map<String, dynamic>> restaurants = [
    {
      'name': 'Ресторан Гурман',
      'description': 'Лучшие блюда европейской кухни',
      'image': 'assets/images/restaurant_1.jpg',
      'menu': [
        {'name': 'Стейк', 'price': 1200, 'image': 'assets/images/steak.jpg'},
        {
          'name': 'Салат Цезарь',
          'price': 450,
          'image': 'assets/images/caesar.jpg'
        },
      ],
    },
    {
      'name': 'Суши Мастер',
      'description': 'Свежие суши и роллы',
      'image': 'assets/images/restaurant_2.jpg',
      'menu': [
        {
          'name': 'Ролл Филадельфия',
          'price': 600,
          'image': 'assets/images/philadelphia.jpg'
        },
        {
          'name': 'Суши с лососем',
          'price': 300,
          'image': 'assets/images/salmon_sushi.jpg'
        },
      ],
    },
    {
      'name': 'Пицца Хаус',
      'description': 'Итальянская пицца на любой вкус',
      'image': 'assets/images/restaurant_3.jpg',
      'menu': [
        {
          'name': 'Пицца Маргарита',
          'price': 700,
          'image': 'assets/images/margherita.jpg'
        },
        {
          'name': 'Пицца Пепперони',
          'price': 800,
          'image': 'assets/images/pepperoni.jpg'
        },
      ],
    },
  ];

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
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        itemCount: restaurants.length,
        itemBuilder: (context, index) {
          final restaurant = restaurants[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        restaurant['image'],
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
                            restaurant['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            restaurant['description'],
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/restaurant',
                          arguments: restaurant,
                        );
                      },
                      child: Text(
                        'Подробнее',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/food_selection',
                          arguments: restaurant['menu'],
                        );
                      },
                      child: Text(
                        'Посмотреть меню',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
