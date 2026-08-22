import 'package:get/get.dart';

class HowToMakeController extends GetxController {
  final steps = <CookingStepModel>[
    CookingStepModel(
      number: 1,
      title: 'Wash the vegetables',
      description:
          'Thoroughly wash all the vegetables under\n'
          'running water and drain well.',
      image: 'assets/images/food_detail/wash_vegetable.png',
    ),
    CookingStepModel(
      number: 2,
      title: 'Prepares the Ingredients',
      description:
          'Cut the cucumber into slices, cherry tomatoes\n'
          'in half, and onion into thin rings.',
      image: 'assets/images/food_detail/prepare_vegetable.png',
    ),
    CookingStepModel(
      number: 3,
      title: 'Add the Lettuce',
      description:
          'Place the lettuce in a large bowl\n'
          'as the base of the salad',
      image: 'assets/images/food_detail/add_the_lettuce.png',
    ),
    CookingStepModel(
      number: 4,
      title: 'Add Vegetables',
      description:
          'Add cucumber, cherry tomatoes, and\n'
          'red onion on top of the lettuce.',
      image: 'assets/images/food_detail/add_vegetables.png',
    ),
    CookingStepModel(
      number: 5,
      title: 'Add Cheese',
      description:
          'Add feta cheese or white cheese cubes\n'
          'for extra flavor.',
      image: 'assets/images/food_detail/add_cheese.png',
    ),
    CookingStepModel(
      number: 6,
      title: 'Make the Dressing & Serve',
      description:
          'Mix olive oil, lemon juice, salt, and black pepper.\n'
          'Pour over the salad and toss gently. Serve fresh!',
      image: 'assets/images/food_detail/make_the_dressing.png',
    ),
  ];

  void goBack() {
    Get.back();
  }
}

class CookingStepModel {
  final int number;
  final String title;
  final String description;
  final String image;

  CookingStepModel({
    required this.number,
    required this.title,
    required this.description,
    required this.image,
  });
}
