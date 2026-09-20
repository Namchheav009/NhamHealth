import 'package:flutter/material.dart';

class IngredientVisual {
  const IngredientVisual({
    this.imageUrl,
    required this.fallbackIcon,
    required this.iconColor,
    required this.backgroundColor,
    required this.defaultRole,
  });

  final String? imageUrl;
  final IconData fallbackIcon;
  final Color iconColor;
  final Color backgroundColor;
  final String defaultRole;
}

class IngredientVisualService {
  IngredientVisualService._();

  static IngredientVisual resolve(
    String name, {
    String? componentType,
    String? visibleEvidence,
    String? customRole,
    String? customImageUrl,
  }) {
    if (customImageUrl != null && customImageUrl.trim().isNotEmpty) {
      final base = _match(name.toLowerCase(), componentType?.toLowerCase());
      return IngredientVisual(
        imageUrl: customImageUrl.trim(),
        fallbackIcon: base.fallbackIcon,
        iconColor: base.iconColor,
        backgroundColor: base.backgroundColor,
        defaultRole:
            customRole?.isNotEmpty == true ? customRole! : base.defaultRole,
      );
    }

    final matched = _match(name.toLowerCase(), componentType?.toLowerCase());
    if (customRole != null && customRole.trim().isNotEmpty) {
      return IngredientVisual(
        imageUrl: matched.imageUrl,
        fallbackIcon: matched.fallbackIcon,
        iconColor: matched.iconColor,
        backgroundColor: matched.backgroundColor,
        defaultRole: customRole.trim(),
      );
    }
    return matched;
  }

  static IngredientVisual _match(String n, String? compType) {
    // Matcha / Green Tea
    if (n.contains('matcha') || n.contains('green tea')) {
      return const IngredientVisual(
        imageUrl:
            'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=240&q=80',
        fallbackIcon: Icons.grass_rounded,
        iconColor: Color(0xFF2E7D32),
        backgroundColor: Color(0xFFE8F5E9),
        defaultRole: 'Main flavor',
      );
    }

    // Milk / Cream / Dairy
    if (n.contains('milk') ||
        n.contains('cream') ||
        n.contains('dairy') ||
        n.contains('condensed')) {
      return const IngredientVisual(
        imageUrl:
            'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=240&q=80',
        fallbackIcon: Icons.local_drink_rounded,
        iconColor: Color(0xFF1E88E5),
        backgroundColor: Color(0xFFE3F2FD),
        defaultRole: 'Creamy base',
      );
    }

    // Tapioca / Boba / Pearls / Jelly
    if (n.contains('tapioca') ||
        n.contains('boba') ||
        n.contains('pearl') ||
        n.contains('jelly')) {
      return const IngredientVisual(
        imageUrl:
            'https://images.unsplash.com/photo-1558857563-b37cf5a297e2?auto=format&fit=crop&w=240&q=80',
        fallbackIcon: Icons.bubble_chart_rounded,
        iconColor: Color(0xFF424242),
        backgroundColor: Color(0xFFEEEEEE),
        defaultRole: 'Boba topping',
      );
    }

    // Sweetener / Sugar / Syrup / Honey
    if (n.contains('sugar') ||
        n.contains('sweetener') ||
        n.contains('syrup') ||
        n.contains('honey')) {
      return const IngredientVisual(
        imageUrl:
            'https://images.unsplash.com/photo-1587735243615-c03f25aaff15?auto=format&fit=crop&w=240&q=80',
        fallbackIcon: Icons.grain_rounded,
        iconColor: Color(0xFFE65100),
        backgroundColor: Color(0xFFFFF3E0),
        defaultRole: 'Added sugar',
      );
    }

    // Rice / Grains / Quinoa
    if (n.contains('rice') || n.contains('grain') || n.contains('quinoa')) {
      return const IngredientVisual(
        imageUrl:
            'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=240&q=80',
        fallbackIcon: Icons.rice_bowl_rounded,
        iconColor: Color(0xFF6D4C41),
        backgroundColor: Color(0xFFEFEBE9),
        defaultRole: 'Carb base',
      );
    }

    // Beef / Steak
    if (n.contains('beef') || n.contains('steak') || n.contains('tenderloin')) {
      return const IngredientVisual(
        imageUrl:
            'https://images.unsplash.com/photo-1588168333986-5078d3ae3976?auto=format&fit=crop&w=240&q=80',
        fallbackIcon: Icons.kebab_dining_rounded,
        iconColor: Color(0xFFC2185B),
        backgroundColor: Color(0xFFFCE4EC),
        defaultRole: 'Protein source',
      );
    }

    // Chicken / Poultry
    if (n.contains('chicken') ||
        n.contains('poultry') ||
        n.contains('breast')) {
      return const IngredientVisual(
        imageUrl:
            'https://images.unsplash.com/photo-1604503468506-a8da13d82791?auto=format&fit=crop&w=240&q=80',
        fallbackIcon: Icons.lunch_dining_rounded,
        iconColor: Color(0xFFF57C00),
        backgroundColor: Color(0xFFFFF3E0),
        defaultRole: 'Lean protein',
      );
    }

    // Pork / Bacon
    if (n.contains('pork') || n.contains('bacon') || n.contains('ham')) {
      return const IngredientVisual(
        imageUrl:
            'https://images.unsplash.com/photo-1602498456745-e9503b30470b?auto=format&fit=crop&w=240&q=80',
        fallbackIcon: Icons.lunch_dining_rounded,
        iconColor: Color(0xFFAD1457),
        backgroundColor: Color(0xFFFCE4EC),
        defaultRole: 'Protein source',
      );
    }

    // Fish / Seafood / Salmon / Shrimp / Tuna
    if (n.contains('fish') ||
        n.contains('salmon') ||
        n.contains('shrimp') ||
        n.contains('tuna') ||
        n.contains('seafood')) {
      return const IngredientVisual(
        imageUrl:
            'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?auto=format&fit=crop&w=240&q=80',
        fallbackIcon: Icons.set_meal_rounded,
        iconColor: Color(0xFF0288D1),
        backgroundColor: Color(0xFFE1F5FE),
        defaultRole: 'Healthy seafood',
      );
    }

    // Egg / Omelet
    if (n.contains('egg') || n.contains('omelet') || n.contains('yolk')) {
      return const IngredientVisual(
        imageUrl:
            'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?auto=format&fit=crop&w=240&q=80',
        fallbackIcon: Icons.egg_rounded,
        iconColor: Color(0xFFFFA000),
        backgroundColor: Color(0xFFFFF8E1),
        defaultRole: 'Whole protein',
      );
    }

    // Salad / Greens / Lettuce / Spinach / Tomato
    if (n.contains('salad') ||
        n.contains('lettuce') ||
        n.contains('spinach') ||
        n.contains('greens') ||
        n.contains('tomato') ||
        n.contains('cucumber') ||
        n.contains('carrot') ||
        n.contains('vegetable')) {
      return const IngredientVisual(
        imageUrl:
            'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=240&q=80',
        fallbackIcon: Icons.eco_rounded,
        iconColor: Color(0xFF388E3C),
        backgroundColor: Color(0xFFE8F5E9),
        defaultRole: 'Fresh greens',
      );
    }

    // Oil / Butter / Sauce / Dressing / Garlic
    if (n.contains('oil') ||
        n.contains('butter') ||
        n.contains('sauce') ||
        n.contains('dressing') ||
        n.contains('garlic') ||
        n.contains('pepper') ||
        n.contains('salt')) {
      return const IngredientVisual(
        imageUrl:
            'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=240&q=80',
        fallbackIcon: Icons.opacity_rounded,
        iconColor: Color(0xFFFBC02D),
        backgroundColor: Color(0xFFFFFDE7),
        defaultRole: 'Flavor seasoning',
      );
    }

    // Noodles / Pasta
    if (n.contains('noodle') ||
        n.contains('pasta') ||
        n.contains('spaghetti')) {
      return const IngredientVisual(
        imageUrl:
            'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=240&q=80',
        fallbackIcon: Icons.ramen_dining_rounded,
        iconColor: Color(0xFFEF6C00),
        backgroundColor: Color(0xFFFFF3E0),
        defaultRole: 'Noodle base',
      );
    }

    // Coffee / Tea / Drinks
    if (n.contains('coffee') || n.contains('espresso') || n.contains('latte')) {
      return const IngredientVisual(
        imageUrl:
            'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=240&q=80',
        fallbackIcon: Icons.coffee_rounded,
        iconColor: Color(0xFF5D4037),
        backgroundColor: Color(0xFFEFEBE9),
        defaultRole: 'Brewed coffee',
      );
    }

    // Fruit / Apple / Orange / Banana / Berries
    if (n.contains('fruit') ||
        n.contains('apple') ||
        n.contains('banana') ||
        n.contains('berry') ||
        n.contains('orange') ||
        n.contains('mango')) {
      return const IngredientVisual(
        imageUrl:
            'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?auto=format&fit=crop&w=240&q=80',
        fallbackIcon: Icons.apple_rounded,
        iconColor: Color(0xFFE53935),
        backgroundColor: Color(0xFFFFEBEE),
        defaultRole: 'Fresh fruit',
      );
    }

    // Bread / Toast / Bun
    if (n.contains('bread') || n.contains('toast') || n.contains('bun')) {
      return const IngredientVisual(
        imageUrl:
            'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=240&q=80',
        fallbackIcon: Icons.bakery_dining_rounded,
        iconColor: Color(0xFF8D6E63),
        backgroundColor: Color(0xFFEFEBE9),
        defaultRole: 'Baked carb',
      );
    }

    // Default fallback
    return const IngredientVisual(
      imageUrl: null,
      fallbackIcon: Icons.restaurant_rounded,
      iconColor: Color(0xFF00A651),
      backgroundColor: Color(0xFFEAF7EC),
      defaultRole: 'Ingredient',
    );
  }
}
