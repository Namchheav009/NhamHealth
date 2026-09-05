import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/community/community_post_detail_controller.dart';
import 'community_comments_page.dart';

class CommunityPostDetailPage extends GetView<CommunityPostDetailController> {
  const CommunityPostDetailPage({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    final post = controller.post.value;
    if (post != null) {
      return CommunityCommentsPage(
        key: ValueKey<String>('community-post-${post.id}'),
        post: post,
        canEdit: controller.canEdit,
        onEditPost: controller.canEdit ? controller.updatePost : null,
      );
    }

    if (controller.isLoading.value) {
      return Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(
          backgroundColor: context.appSurface,
          title: const Text('Community post'),
        ),
        body: const SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: PageSkeleton.communityPost(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        title: const Text('Community post'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 42),
              const SizedBox(height: 12),
              Text(
                controller.errorMessage.value ??
                    'The community post could not be loaded.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: controller.load,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  });
}
