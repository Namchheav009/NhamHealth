import 'package:get/get.dart';

import '../../controllers/feed/feed_controller.dart';

class FeedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FeedController>(FeedController.new);
  }
}
