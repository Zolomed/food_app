class MenuItem {
  final String id;
  final String name;
  final int price;
  final String image;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
  });

  factory MenuItem.fromMap(String id, Map<String, dynamic> map) {
    return MenuItem(
      id: id,
      name: map['name'] ?? '',
      price: map['price'] ?? 0,
      image: map['image'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'image': image,
    };
  }
}
