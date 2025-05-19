import 'menu_item.dart';

class Restaurant {
  final String id;
  final String name;
  final String description;
  final String image;
  final List<MenuItem> menu;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.menu,
  });

  factory Restaurant.fromMap(
      String id, Map<String, dynamic> map, List<MenuItem> menu) {
    return Restaurant(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      image: map['image'] ?? '',
      menu: menu,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'image': image,
    };
  }
}
