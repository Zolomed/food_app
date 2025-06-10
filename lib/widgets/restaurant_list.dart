import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/restaurant.dart';

class RestaurantList extends StatelessWidget {
  final List<Restaurant> restaurants;
  final Set<String> favoriteRestaurantIds;
  final Function(String) onFavoriteTap;
  final String searchQuery;

  const RestaurantList({
    super.key,
    required this.restaurants,
    required this.favoriteRestaurantIds,
    required this.onFavoriteTap,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    final filteredRestaurants = searchQuery.isEmpty
        ? restaurants
        : restaurants
            .where((r) =>
                r.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                r.cuisine.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (filteredRestaurants.isEmpty) {
          return Center(child: Text('Нет доступных ресторанов'));
        }
        if (constraints.maxWidth > 700) {
          // Сетка ресторанов для широких экранов
          const minCardWidth = 340.0;
          final crossAxisCount =
              (constraints.maxWidth / minCardWidth).floor().clamp(2, 6);
          final spacing = 24.0;
          final cardWidth =
              (constraints.maxWidth - (crossAxisCount - 1) * spacing - 32) /
                  crossAxisCount;
          final cardHeight = 300.0;
          final aspectRatio = cardWidth / cardHeight;

          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: aspectRatio,
            ),
            itemCount: filteredRestaurants.length,
            itemBuilder: (context, index) {
              final restaurant = filteredRestaurants[index];
              final isFavorite = favoriteRestaurantIds.contains(restaurant.id);
              return _RestaurantCard(
                restaurant: restaurant,
                fixedHeight: cardHeight,
                isFavorite: isFavorite,
                onFavoriteTap: () => onFavoriteTap(restaurant.id),
              );
            },
          );
        } else {
          // Список ресторанов для мобильных устройств
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: filteredRestaurants.length,
            itemBuilder: (context, index) {
              final restaurant = filteredRestaurants[index];
              final isFavorite = favoriteRestaurantIds.contains(restaurant.id);
              return _RestaurantCard(
                restaurant: restaurant,
                fixedHeight: 250,
                isFavorite: isFavorite,
                onFavoriteTap: () => onFavoriteTap(restaurant.id),
              );
            },
          );
        }
      },
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final double fixedHeight;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  const _RestaurantCard({
    required this.restaurant,
    required this.fixedHeight,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final cuisine =
        restaurant.cuisine.isNotEmpty ? restaurant.cuisine : 'Не указано';

    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/food_selection',
              arguments: restaurant,
            );
          },
          child: SizedBox(
            height: fixedHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    // Картинка ресторана с кэшированием
                    ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                      child: restaurant.image.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: restaurant.image,
                              width: double.infinity,
                              height: 140,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                width: double.infinity,
                                height: 140,
                              ),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                            )
                          : Image.asset(
                              restaurant.image,
                              width: double.infinity,
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                    ),
                    // Кнопка "избранное"
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                          size: 28,
                        ),
                        tooltip: isFavorite
                            ? 'Убрать ресторан из избранного'
                            : 'Добавить ресторан в избранное',
                        onPressed: onFavoriteTap,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                restaurant.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.info_outline,
                                  color: Colors.orange),
                              tooltip: 'Информация о ресторане',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(restaurant.name),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (restaurant.description.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8.0),
                                            child: Text(
                                              restaurant.description,
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          ),
                                        Text('Кухня: $cuisine'),
                                        SizedBox(height: 4),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text('Закрыть'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        Text(
                          cuisine,
                          style: TextStyle(color: Colors.black87, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
