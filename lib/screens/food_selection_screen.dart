import 'package:flutter/material.dart';
import '../models/menu_item.dart';

//TODO Сделать сортировку блюд
//TODO сделать избранное
//TODO реализовать правильные переходы
//TODO сделать открытие блюд

class FoodSelectionScreen extends StatefulWidget {
  @override
  _FoodSelectionScreenState createState() => _FoodSelectionScreenState();
}

class _FoodSelectionScreenState extends State<FoodSelectionScreen> {
  final Set<MenuItem> _favoriteItems = {}; // Хранит избранные блюда

  @override
  Widget build(BuildContext context) {
    final List<MenuItem> menu =
        ModalRoute.of(context)!.settings.arguments as List<MenuItem>;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Меню',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        itemCount: menu.length,
        itemBuilder: (context, index) {
          final item = menu[index];
          final isFavorite = _favoriteItems.contains(item);

          return Card(
            margin: EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: item.image.startsWith('http')
                      ? Image.network(
                          item.image,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          item.image,
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
                        item.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '${item.price} р.',
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
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isFavorite) {
                        _favoriteItems.remove(item);
                      } else {
                        _favoriteItems.add(item);
                      }
                    });
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
