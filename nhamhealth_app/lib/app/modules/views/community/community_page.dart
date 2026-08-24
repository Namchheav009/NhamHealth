import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/app_bottom_navigation.dart';
import '../../../widgets/loading_content_transition.dart';
import '../../../widgets/nham_app_bar.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/community/community_controller.dart';
import 'widgets/community_composer_card.dart';
import 'widgets/community_empty_state.dart';
import 'widgets/community_tab_switcher.dart';

class CommunityPage extends GetView<CommunityController> {
  const CommunityPage({super.key});
  static const green = Color(0xFF08A936);
  static const navy = Color(0xFF071A43);

  @override
  Widget build(BuildContext context) => Obx(
    () => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppColors.homeBackground,
        body: AppBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _header(),
                _intro(),
                const SizedBox(height: 14),
                _mainTabs(),
                const SizedBox(height: 4),
                Expanded(
                  child: LoadingContentTransition(
                    isLoading:
                        controller.isLoading.value &&
                        !controller.hasLoaded.value,
                    loading: const SingleChildScrollView(
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.pageHorizontal,
                        4,
                        AppSpacing.pageHorizontal,
                        110,
                      ),
                      child: PageSkeleton.community(),
                    ),
                    content: RefreshIndicator(
                      color: green,
                      onRefresh: controller.reload,
                      child: _body(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _bottomNav(),
      ),
    ),
  );

  Widget _header() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AppSpacing.maxPaddedContentWidth,
      ),
      child: Padding(
        padding: AppSpacing.topBarPagePadding,
        child: NhamAppBar(
          user: controller.authenticatedUser.value,
          unreadNotificationCount: controller.unreadNotificationCount.value,
          onNotifications: () async {
            await Get.toNamed<void>(AppRoutes.notifications);
            await controller.loadTopBar();
          },
          onProfile:
              () => Get.toNamed<void>(
                AppRoutes.profile,
                arguments: controller.authenticatedUser.value,
              ),
        ),
      ),
    ),
  );

  Widget _intro() => _contentWidth(
    Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: navy,
                    letterSpacing: -.4,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Grow healthier, together.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF718078)),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: _showCreatePost,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Post'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _mainTabs() => _contentWidth(
    Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
      ),
      child: CommunityTabSwitcher(
        selected: controller.section.value,
        onChanged: controller.selectSection,
      ),
    ),
  );

  Widget _body() {
    switch (controller.section.value) {
      case CommunitySection.feed:
        return _feed();
      case CommunitySection.people:
        return _friends();
    }
  }

  Widget _friends() {
    final view = controller.friendsView.value;
    final isAdd = view == FriendsView.addFriends;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        12,
        AppSpacing.pageHorizontal,
        115,
      ),
      children: [
        _contentWidth(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _title(view),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _subtitle(view),
                style: const TextStyle(fontSize: 12, color: Color(0xFF718078)),
              ),
              const SizedBox(height: 14),
              _peopleSections(),
              const SizedBox(height: 14),
              TextField(
                onChanged: controller.updateSearch,
                decoration: InputDecoration(
                  hintText:
                      isAdd
                          ? 'Search for people by name...'
                          : 'Search ${_title(view).toLowerCase()}...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.black,
                    size: 27,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FB),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (isAdd) ...[const SizedBox(height: 14), _peopleFilters()],
              const SizedBox(height: 24),
              if (!isAdd)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${controller.countFor(view)} ${_title(view).toLowerCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Text(
                      'Newest',
                      style: TextStyle(color: navy, fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: navy,
                    ),
                  ],
                ),
              if (!isAdd) const SizedBox(height: 10),
              if (controller.filteredPeople.isEmpty)
                const CommunityEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No people found',
                  message: 'Try another name, interest, or filter.',
                ),
              ...controller.filteredPeople.map(
                (person) => _personTile(person, view),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _peopleSections() {
    const labels = ['Friends', 'Requests', 'Following', 'Discover'];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FriendsView.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final section = FriendsView.values[index];
          final selected = controller.friendsView.value == section;
          return ChoiceChip(
            label: Text(labels[index]),
            selected: selected,
            onSelected: (_) => controller.selectFriendsView(section),
            showCheckmark: false,
            selectedColor: const Color(0xFFE3F6E8),
            backgroundColor: Colors.white,
            side: BorderSide(
              color:
                  selected ? const Color(0xFFB8E4C5) : const Color(0xFFE3E7E5),
            ),
            labelStyle: TextStyle(
              color: selected ? const Color(0xFF087B3A) : Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          );
        },
      ),
    );
  }

  Widget _personTile(CommunityPerson person, FriendsView view) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .97),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE3EBE5)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08173D25),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFE9F4EC),
          backgroundImage: NetworkImage(person.avatarUrl),
          onBackgroundImageError: (_, _) {},
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                person.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10152A),
                ),
              ),
              if (person.detail != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      view == FriendsView.addFriends
                          ? Icons.group
                          : Icons.schedule,
                      size: 14,
                      color: const Color(0xFF6076A7),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        person.detail!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6076A7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (person.tags.isNotEmpty) ...[
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children:
                      person.tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF7EE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF078D35),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ],
          ),
        ),
        if (view == FriendsView.followers) ...[
          _outlineButton(
            'Accept',
            green,
            () => controller.updateConnection(person, view),
          ),
          const SizedBox(width: 6),
          _outlineButton(
            'Decline',
            Colors.red,
            () => controller.declineFollower(person),
          ),
        ] else
          _outlineButton(
            controller.connectionStatuses[person.id] ??
                (view == FriendsView.friends
                    ? 'Message'
                    : view == FriendsView.following
                    ? 'Following'
                    : 'Add'),
            green,
            () => controller.updateConnection(person, view),
          ),
        const SizedBox(width: 5),
        const Icon(Icons.more_vert, size: 22, color: Colors.black),
      ],
    ),
  );

  Widget _outlineButton(String text, Color color, VoidCallback onPressed) =>
      OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: .75)),
          minimumSize: const Size(62, 35),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );
  Widget _peopleFilters() => Container(
    height: 42,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F5F3),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE1E8E3)),
    ),
    child: Row(
      children: [
        _peopleFilterOption(
          icon: Icons.people_alt_rounded,
          label: 'All people',
          filter: PeopleFilter.all,
        ),
        _peopleFilterOption(
          icon: Icons.group_outlined,
          label: 'Mutual friends',
          filter: PeopleFilter.mutualFriends,
        ),
      ],
    ),
  );

  Widget _peopleFilterOption({
    required IconData icon,
    required String label,
    required PeopleFilter filter,
  }) {
    final selected = controller.peopleFilter.value == filter;
    return Expanded(
      child: InkWell(
        onTap: () => controller.selectPeopleFilter(filter),
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow:
                selected
                    ? const [
                      BoxShadow(
                        color: Color(0x0D173D25),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? green : const Color(0xFF718078),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color:
                      selected
                          ? const Color(0xFF087B3A)
                          : const Color(0xFF59645D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feed() => ListView(
    physics: const AlwaysScrollableScrollPhysics(
      parent: BouncingScrollPhysics(),
    ),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.pageHorizontal,
      12,
      AppSpacing.pageHorizontal,
      115,
    ),
    children: [
      _contentWidth(
        Column(
          children: [
            _createPost(),
            _feedFilters(),
            const SizedBox(height: 14),
            if (controller.visiblePosts.isEmpty)
              const CommunityEmptyState(
                icon: Icons.dynamic_feed_outlined,
                title: 'Nothing here yet',
                message: 'Follow more people or check another feed filter.',
              ),
            ...controller.visiblePosts.map(_postCard),
          ],
        ),
      ),
    ],
  );

  Widget _createPost() => CommunityComposerCard(onTap: _showCreatePost);

  Widget _feedFilters() {
    const labels = ['For You', 'Following', 'Latest'];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: CommunityFeedFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = CommunityFeedFilter.values[index];
          final selected = controller.feedFilter.value == filter;
          return ChoiceChip(
            label: Text(labels[index]),
            selected: selected,
            onSelected: (_) => controller.selectFeedFilter(filter),
            showCheckmark: false,
            selectedColor: const Color(0xFFE3F6E8),
            backgroundColor: Colors.white,
            side: BorderSide(
              color:
                  selected ? const Color(0xFFB8E4C5) : const Color(0xFFE3E7E5),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            labelStyle: TextStyle(
              color: selected ? const Color(0xFF087B3A) : Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          );
        },
      ),
    );
  }

  Widget _postCard(CommunityPost post) => Container(
    padding: const EdgeInsets.all(15),
    margin: const EdgeInsets.only(bottom: 14),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFFEAF7EE),
              backgroundImage:
                  post.authorAvatarUrl.isEmpty
                      ? null
                      : NetworkImage(post.authorAvatarUrl),
              child:
                  post.authorAvatarUrl.isEmpty
                      ? const Icon(Icons.person_outline_rounded, color: green)
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.author,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${post.ageLabel} • ${post.role}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          post.title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          post.description,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Color(0xFF566159),
          ),
        ),
        if (post.tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children:
                post.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF8F0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '#${tag.replaceAll(' ', '')}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF27804B),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
        if (post.imageBytes != null || post.imageUrl.isNotEmpty) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child:
                post.imageBytes != null
                    ? Image.memory(
                      post.imageBytes!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                    : Image.network(
                      post.imageUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, _, _) => const SizedBox(
                            height: 220,
                            child: Center(child: Icon(Icons.image_outlined)),
                          ),
                    ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: () => controller.togglePostLike(post),
              tooltip: 'Like post',
              icon: Icon(
                post.isLiked ? Icons.favorite : Icons.favorite_border,
                color: post.isLiked ? Colors.red : navy,
              ),
            ),
            Text('${post.likes}'),
            const SizedBox(width: 20),
            const Icon(Icons.chat_bubble_outline, size: 20),
            const SizedBox(width: 6),
            Text('${post.comments}'),
            const Spacer(),
            IconButton(
              onPressed: () => controller.sharePost(post),
              tooltip: 'Share post',
              icon: const Icon(Icons.reply, color: navy),
            ),
          ],
        ),
      ],
    ),
  );

  Future<void> _showCreatePost() async {
    final title = TextEditingController();
    final description = TextEditingController();
    final imagePicker = ImagePicker();
    Uint8List? selectedImage;

    await Get.dialog<void>(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 640),
          child: StatefulBuilder(
            builder:
                (context, setDialogState) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_note_rounded, color: green),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Create a post',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: Get.back,
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              TextField(
                                controller: title,
                                autofocus: true,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: _postInput('Title (optional)'),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: description,
                                maxLines: 4,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: _postInput(
                                  'What would you like to share?',
                                  alignLabelWithHint: true,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (selectedImage != null) ...[
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.memory(
                                          selectedImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Material(
                                          color: Colors.black54,
                                          shape: const CircleBorder(),
                                          child: IconButton(
                                            onPressed:
                                                () => setDialogState(
                                                  () => selectedImage = null,
                                                ),
                                            tooltip: 'Remove image',
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              color: Colors.white,
                                              size: 19,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final image = await imagePicker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 82,
                                      maxWidth: 1600,
                                    );
                                    if (image == null) return;
                                    final bytes = await image.readAsBytes();
                                    if (context.mounted) {
                                      setDialogState(
                                        () => selectedImage = bytes,
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    selectedImage == null
                                        ? Icons.add_photo_alternate_outlined
                                        : Icons.image_outlined,
                                  ),
                                  label: Text(
                                    selectedImage == null
                                        ? 'Add image'
                                        : 'Change image',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: green,
                                    side: const BorderSide(
                                      color: Color(0xFFB8E4C5),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: Get.back,
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () async {
                              if (description.text.trim().isEmpty) {
                                Get.snackbar(
                                  'Add your message',
                                  'Write something you would like to share.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  margin: const EdgeInsets.all(16),
                                );
                                return;
                              }
                              try {
                                await controller.addPost(
                                  title: title.text,
                                  description: description.text,
                                  imageBytes: selectedImage,
                                );
                                Get.back<void>();
                              } on Object catch (error) {
                                Get.snackbar(
                                  'Could not publish',
                                  error.toString(),
                                  snackPosition: SnackPosition.BOTTOM,
                                  margin: const EdgeInsets.all(16),
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                            ),
                            child: const Text('Publish'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
    title.dispose();
    description.dispose();
  }

  InputDecoration _postInput(String label, {bool alignLabelWithHint = false}) =>
      InputDecoration(
        labelText: label,
        alignLabelWithHint: alignLabelWithHint,
        filled: true,
        fillColor: const Color(0xFFF7FAF8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white.withValues(alpha: .98),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: const Color(0xFFE3EBE5)),
    boxShadow: const [
      BoxShadow(color: Color(0x0A173D25), blurRadius: 18, offset: Offset(0, 6)),
    ],
  );
  Widget _contentWidth(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AppSpacing.maxPaddedContentWidth,
      ),
      child: child,
    ),
  );
  String _title(FriendsView view) =>
      const ['Friends', 'Followers', 'Following', 'Add Friends'][view.index];
  String _subtitle(FriendsView view) =>
      const [
        'Your accepted connections.',
        'People who want to connect with you.',
        'People and accounts you follow.',
        'Find and connect with new people.',
      ][view.index];
  Widget _bottomNav() => SafeArea(
    top: false,
    minimum: AppSpacing.navigationMargin,
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: AppBottomNavigation(
          selectedIndex: 3,
          onSelect: (index) {
            if (index == 2) {
              _showCreatePost();
              return;
            }
            if (index == 0) Get.offNamed<void>(AppRoutes.home);
            if (index == 1) Get.offNamed<void>(AppRoutes.meals);
            if (index == 4) Get.offNamed<void>(AppRoutes.settings);
          },
        ),
      ),
    ),
  );
}
