class MenuItem {
  final String id;
  final String name;
  final int price;
  final String image;
  final String? category;
  final String? weight;
  final String? description;
  final List<String> allergens;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    this.category,
    this.weight,
    this.description,
    this.allergens = const [],
  });

  factory MenuItem.fromMap(String id, Map<String, dynamic> map) {
    return MenuItem(
      id: id,
      name: map['name'] ?? '',
      price: map['price'] ?? 0,
      image: map['image'] ?? '',
      category: map['category'],
      weight: map['weight'],
      description: map['description'],
      allergens: List<String>.from(map['allergens'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'image': image,
      'category': category,
      'weight': weight,
      'description': description,
      'allergens': allergens,
    };
  }
}
