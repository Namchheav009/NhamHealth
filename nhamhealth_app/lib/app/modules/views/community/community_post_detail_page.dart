import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
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
        titleKey: 'community.post_title',
      );
    }

    if (controller.isLoading.value) {
      return _pageShell(
        context,
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            4,
            AppSpacing.pageHorizontal,
            24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
              child: PageSkeleton.communityPost(),
            ),
          ),
        ),
      );
    }

    return _pageShell(
      context,
      Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 42),
              const SizedBox(height: 12),
              Text(
                controller.errorMessage.value ??
                    'community.post_load_failed'.tr,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: controller.load,
                child: Text('common.try_again'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  });

  Widget _pageShell(BuildContext context, Widget body) =>
      MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: Scaffold(
          backgroundColor: context.appBackground,
          body: AppBackground(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSpacing.maxPaddedContentWidth,
                      ),
                      child: Padding(
                        padding: AppSpacing.topBarPagePadding,
                        child: AppBackHeader(
                          title: 'community.post_title'.tr,
                          onBack: Get.back,
                          backButtonKey: const ValueKey<String>(
                            'community-post-back-button',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: body),
                ],
              ),
            ),
          ),
        ),
      );
}
