import 'package:get/get.dart';

class IngredientController extends GetxController {
  final ingredients = <IngredientModel>[
    IngredientModel(
      name: 'Lettuce',
      description:
          'Fresh leafy greens that make\nthe salad light and crisp.',
      image: 'assets/images/food_detail/lettuce.png',
    ),
    IngredientModel(
      name: 'Cherry Tomato',
      description:
          'Juicy tomatoes that add\nsweetness and bright color.',
      image: 'assets/images/food_detail/cherry_tomato.png',
    ),
    IngredientModel(
      name: 'Cucumber',
      description:
          'Cool, hydrating slices that give\na refreshing crunch',
      image: 'assets/images/food_detail/cucumber.png',
    ),
    IngredientModel(
      name: 'Red Onion',
      description:
          'Thin onion slices that add\na mild sharp flavor',
      image: 'assets/images/food_detail/red_onion.png',
    ),
    IngredientModel(
      name: 'Feta Cheese',
      description:
          'Soft white cheese cubes that\nbring a creamy, salty taste.',
      image: 'assets/images/food_detail/feta_cheese.png',
    ),
    IngredientModel(
      name: 'Parsley',
      description:
          'A fresh herb that adds aroma\nand healthy finishing touch.',
      image: 'assets/images/food_detail/parsley.png',
    ),
  ];

  void goBack() {
    Get.back();
  }
}

class IngredientModel {
  final String name;
  final String description;
  final String image;

  IngredientModel({
    required this.name,
    required this.description,
    required this.image,
  });
}