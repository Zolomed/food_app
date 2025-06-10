import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/widgets/food_card.dart';

void main() {
  // Тест: Проверка FoodCard — отображение названия и цены блюда
  testWidgets('FoodCard отображает название и цену',
      (WidgetTester tester) async {
    // Создаём тестовый FoodCard
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoodCard(
            image:
                'https://www.sortiraparis.com/hotel-restaurant/restaurant/articles/281096-sphere-le-beau-restaurant-gastronomique-paris-8e-se-devoile', // Подставьте любой валидный URL
            name: 'Тестовое блюдо',
            price: 123.45,
            isFavorite: false,
            quantity: 0,
            onFavoriteTap: () {},
            onAdd: () {},
            onRemove: () {},
          ),
        ),
      ),
    );

    // Проверяем, что название и цена отображаются
    expect(find.text('Тестовое блюдо'), findsOneWidget);
    expect(find.text('123.45₽'), findsOneWidget);
  });
}
