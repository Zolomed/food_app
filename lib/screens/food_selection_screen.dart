import 'package:flutter/material.dart';
//TODO Сделать сортировку блюд
//TODO убрать кнопку назад
//TODO сделать избранное
//TODO реализовать правильные переходы

class FoodSelectionScreen extends StatefulWidget {
  @override
  _FoodSelectionScreenState createState() => _FoodSelectionScreenState();
}

class _FoodSelectionScreenState extends State<FoodSelectionScreen> {
  final List<Map<String, dynamic>> foodItems = [
    {
      'name': 'Курица по-гавайски',
      'description': 'Курица, сыр и ананас',
      'price': 500,
      'image': 'assets/images/hawaiian_chicken.jpg',
      'rating': 4.5,
      'isFavorite': false,
    },
    {
      'name': 'Греческий салат',
      'description': 'Салат с запеченным лососем',
      'price': 150,
      'image': 'assets/images/greek_salad.jpg',
      'rating': 4.8,
      'isFavorite': false,
    },
    {
      'name': 'Пицца Маргарита',
      'description': 'Томатный соус, сыр, базилик',
      'price': 600,
      'image': 'assets/images/margherita_pizza.jpg',
      'rating': 4.7,
      'isFavorite': false,
    },
  ];

  void toggleFavorite(int index) {
    setState(() {
      foodItems[index]['isFavorite'] = !foodItems[index]['isFavorite'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Позволяет экрану адаптироваться к клавиатуре
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Убираем кнопку "Назад"
        title: Text(
          'Выбор еды',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.sort, color: Colors.orange),
            onPressed: () {
              // Логика сортировки
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: foodItems.length,
              itemBuilder: (context, index) {
                final item = foodItems[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          item['image'],
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
                              item['description'],
                              style: TextStyle(color: Colors.grey),
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
                            SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(Icons.star,
                                    color: Colors.orange, size: 16),
                                SizedBox(width: 5),
                                Text('${item['rating']}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          item['isFavorite']
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: item['isFavorite'] ? Colors.red : Colors.grey,
                        ),
                        onPressed: () {
                          toggleFavorite(index);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
