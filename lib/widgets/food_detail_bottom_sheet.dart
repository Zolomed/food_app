import 'package:flutter/material.dart';
import '../models/menu_item.dart';

class FoodDetailBottomSheet extends StatelessWidget {
  final MenuItem item;
  final double screenWidth;
  final double minHeight;
  final double maxHeight;
  final VoidCallback onAddToCart;
  final List<String>? userAllergies;

  const FoodDetailBottomSheet({
    super.key,
    required this.item,
    required this.screenWidth,
    required this.minHeight,
    required this.maxHeight,
    required this.onAddToCart,
    this.userAllergies,
  });

  @override
  Widget build(BuildContext context) {
    final double desiredHeight =
        (MediaQuery.of(context).size.height * 0.8).clamp(minHeight, maxHeight);

    // Проверяем, содержит ли блюдо аллергены пользователя
    final bool containsAllergen = userAllergies != null &&
        item.allergens.any((a) => userAllergies!.contains(a));

    return Container(
      constraints: BoxConstraints(
        minHeight: minHeight,
        maxHeight: desiredHeight,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: minHeight,
            maxHeight: desiredHeight,
          ),
          child: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 16),
                Container(
                  width: 60,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                SizedBox(height: 16),
                // Название блюда
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Предупреждение о содержании аллергенов
                if (containsAllergen)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Внимание! Это блюдо содержит ваши аллергены.',
                            style: TextStyle(color: Colors.red, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Картинка блюда
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: item.image.startsWith('http')
                      ? Image.network(
                          item.image,
                          width: screenWidth,
                          height: 220,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          item.image,
                          width: screenWidth,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                ),
                SizedBox(height: 20),
                // Описание блюда
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    item.description ?? '',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                if ((item.ingredients ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12),
                    child: Text(
                      item.ingredients!,
                      style: TextStyle(fontSize: 15, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (item.weight != null && item.weight!.isNotEmpty)
                        Text(
                          '${item.weight} г',
                          style:
                              TextStyle(fontSize: 15, color: Colors.grey[700]),
                        ),
                      if (item.weight != null && item.weight!.isNotEmpty)
                        SizedBox(width: 10),
                      Text(
                        '${item.price} ₽',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                // Кнопка добавления блюда в корзину
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onAddToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        'Добавить в корзину',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
