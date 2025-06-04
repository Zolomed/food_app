import 'package:flutter/material.dart';

class FoodCard extends StatelessWidget {
  final String image;
  final String name;
  final double price;
  final String? weight;
  final bool isFavorite;
  final int quantity;
  final VoidCallback onFavoriteTap;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool allergenWarning;
  final bool isTotalLimit;

  const FoodCard({
    super.key,
    required this.image,
    required this.name,
    required this.price,
    this.weight,
    required this.isFavorite,
    required this.quantity,
    required this.onFavoriteTap,
    required this.onAdd,
    required this.onRemove,
    this.allergenWarning = false,
    this.isTotalLimit = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F7F5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Картинка блюда и кнопка "избранное"
              Padding(
                padding: const EdgeInsets.only(
                    left: 12, right: 12, top: 12, bottom: 0),
                child: Stack(
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: image.startsWith('http')
                            ? Image.network(
                                image,
                                height: constraints.maxWidth > 220 ? 150 : 110,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                image,
                                height: constraints.maxWidth > 220 ? 150 : 110,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: onFavoriteTap,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Цена блюда
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${price.toStringAsFixed(2)}₽',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Название блюда
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Вес блюда
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  weight != null && weight!.isNotEmpty ? '$weight г' : '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              // Предупреждение об аллергенах
              if (allergenWarning)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Содержит ваш аллерген',
                          style: TextStyle(color: Colors.red, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              // Кнопки добавления/удаления блюда или кнопка "Добавить"
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: quantity > 0
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: onRemove,
                          ),
                          Text(
                            '$quantity',
                            style: const TextStyle(fontSize: 18),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: isTotalLimit ? null : onAdd,
                          ),
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isTotalLimit ? null : onAdd,
                          icon: const Icon(Icons.add, color: Colors.black),
                          label: const Text(
                            'Добавить',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: const BorderSide(
                                color: Colors.black12, width: 1),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
              ),
              // Сообщение о лимите блюд в заказе
              if (isTotalLimit)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Максимум 30 блюд в заказе',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
