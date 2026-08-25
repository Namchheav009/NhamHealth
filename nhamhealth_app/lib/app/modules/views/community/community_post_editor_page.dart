import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/community/community_post.dart';
import '../../models/community/community_tag.dart';
import '../../repositories/community/community_repository.dart';

class CommunityPostDraft {
  const CommunityPostDraft({
    required this.title,
    required this.description,
    required this.imageBytes,
    required this.removeImage,
    required this.visibility,
    required this.allowComments,
    required this.allowReplies,
    required this.tagIds,
  });

  final String title;
  final String description;
  final List<Uint8List> imageBytes;
  final bool removeImage;
  final CommunityPostVisibility visibility;
  final bool allowComments;
  final bool allowReplies;
  final List<int> tagIds;
}

/// A shared, full-screen composer for both new and existing community posts.
class CommunityPostEditorPage extends StatefulWidget {
  const CommunityPostEditorPage({
    required this.authorName,
    required this.authorAvatarUrl,
    required this.onSubmit,
    this.post,
    super.key,
  });

  final CommunityPost? post;
  final String authorName;
  final String authorAvatarUrl;
  final Future<void> Function(CommunityPostDraft draft) onSubmit;

  @override
  State<CommunityPostEditorPage> createState() => _CommunityPostEditorPageState();
}

class _CommunityPostEditorPageState extends State<CommunityPostEditorPage> {
  static const _green = Color(0xFF08A936);
  static const _ink = Color(0xFF151A16);
  static const _muted = Color(0xFF626A7A);

  late final TextEditingController _title;
  late final TextEditingController _description;
  final _picker = ImagePicker();
  final List<Uint8List> _imageBytes = [];
  late CommunityPostVisibility _visibility;
  late bool _allowComments;
  late bool _allowReplies;
  bool _removeExistingImage = false;
  bool _submitting = false;
  List<CommunityTag> _tags = const [];
  late final Set<int> _selectedTagIds;

  bool get _editing => widget.post != null;
  List<String> get _existingImageUrls =>
      _removeExistingImage ? const [] : widget.post?.imageUrls ?? const [];
  bool get _hasMedia => _imageBytes.isNotEmpty || _existingImageUrls.isNotEmpty;
  int get _imageCount => _imageBytes.length + _existingImageUrls.length;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.post?.title ?? '');
    _description = TextEditingController(text: widget.post?.description ?? '');
    _visibility = widget.post?.visibility ?? CommunityPostVisibility.public;
    _allowComments = widget.post?.allowComments ?? true;
    _allowReplies = widget.post?.allowReplies ?? true;
    _selectedTagIds = {...?widget.post?.tagIds};
    _description.addListener(_refresh);
    _loadTags();
  }

  @override
  void dispose() {
    _description
      ..removeListener(_refresh)
      ..dispose();
    _title.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadTags() async {
    try {
      final tags = await Get.find<CommunityRepository>().getTags();
      if (mounted) setState(() => _tags = tags);
    } on Object {
      // Tag selection stays optional when the tag service is unavailable.
    }
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final remaining = 6 - _imageCount;
      if (remaining <= 0) {
        Get.snackbar('Image limit reached', 'A post can include up to 6 images.');
        return;
      }
      final files = source == ImageSource.gallery
          ? await _picker.pickMultiImage(imageQuality: 82, maxWidth: 1600)
          : [
              ?await _picker.pickImage(
                source: source,
                imageQuality: 82,
                maxWidth: 1600,
              ),
            ];
      if (files.isEmpty) return;
      final selected = files.take(remaining).toList(growable: false);
      final bytes = await Future.wait(selected.map((image) => image.readAsBytes()));
      if (!mounted) return;
      setState(() {
        _imageBytes.addAll(bytes);
      });
      if (files.length > remaining) {
        Get.snackbar('Only 6 images allowed', 'The first $remaining selected images were added.');
      }
    } on Object catch (error) {
      if (mounted) Get.snackbar('Could not add image', error.toString());
    }
  }

  Future<void> _submit() async {
    final description = _description.text.trim();
    if (description.isEmpty) {
      Get.snackbar(
        'Add your message',
        'Write something you would like to share.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        CommunityPostDraft(
          title: _title.text,
          description: description,
          imageBytes: List.unmodifiable(_imageBytes),
          removeImage: _removeExistingImage,
          visibility: _visibility,
          allowComments: _allowComments,
          allowReplies: _allowReplies,
          tagIds: _selectedTagIds.toList(growable: false),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      Get.snackbar(
        _editing ? 'Post updated' : 'Post published',
        _editing
            ? 'Your changes have been saved.'
            : 'Your post has been shared with the community.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } on Object catch (error) {
      if (mounted) {
        Get.snackbar(
          _editing ? 'Could not update post' : 'Could not publish',
          error.toString(),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFFEFF),
    appBar: AppBar(
      backgroundColor: const Color(0xFFFFFEFF),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      leadingWidth: 72,
      leading: IconButton(
        onPressed: _submitting ? null : () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.close_rounded, color: _green, size: 30),
        tooltip: 'Close',
      ),
      title: Text(
        _editing ? 'Edit Post' : 'Create Post',
        style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w800),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              disabledBackgroundColor: const Color(0xFF87D9A2),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: const StadiumBorder(),
            ),
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_editing ? 'Save' : 'Publish', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        children: [
          _author(),
          const SizedBox(height: 30),
          _input(
            controller: _title,
            hint: 'Title (optional)',
            minLines: 1,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _input(
            controller: _description,
            hint: 'Share a win, question, healthy meal, or idea...',
            minLines: 6,
            maxLines: 9,
            maxLength: 2000,
            isDescription: true,
          ),
          const SizedBox(height: 12),
          _tagsSection(),
          const SizedBox(height: 24),
          _mediaCard(),
          const SizedBox(height: 22),
          _settingsCard(),
        ],
      ),
    ),
  );

  Widget _author() => Row(
    children: [
      CircleAvatar(
        radius: 31,
        backgroundColor: const Color(0xFFEAF7EE),
        backgroundImage: widget.authorAvatarUrl.isEmpty ? null : NetworkImage(widget.authorAvatarUrl),
        child: widget.authorAvatarUrl.isEmpty
            ? Text(
                _initials(widget.authorName),
                style: const TextStyle(color: _green, fontSize: 18, fontWeight: FontWeight.w800),
              )
            : null,
      ),
      const SizedBox(width: 15),
      Expanded(
        child: Text(widget.authorName, style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w800)),
      ),
    ],
  );

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required int minLines,
    required int maxLines,
    int? maxLength,
    bool isDescription = false,
  }) => TextField(
    controller: controller,
    minLines: minLines,
    maxLines: maxLines,
    maxLength: maxLength,
    textCapitalization: TextCapitalization.sentences,
    style: const TextStyle(color: _ink, fontSize: 16),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _muted, fontSize: 16),
      filled: true,
      fillColor: const Color(0xFFFFFEFF),
      contentPadding: const EdgeInsets.fromLTRB(20, 17, 20, 12),
      enabledBorder: _inputBorder(),
      focusedBorder: _inputBorder(color: _green, width: 1.5),
      counterText: isDescription ? '${_description.text.length}/2000' : '',
      counterStyle: const TextStyle(color: _muted, fontSize: 12),
    ),
  );

  OutlineInputBorder _inputBorder({Color color = const Color(0xFFD0D4DC), double width = 1}) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: color, width: width));

  Widget _tagsSection() => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (final tag in _tags.where((tag) => _selectedTagIds.contains(tag.id)))
        InputChip(
          label: Text('#${tag.name}', style: const TextStyle(fontSize: 13)),
          onDeleted: _submitting
              ? null
              : () => setState(() => _selectedTagIds.remove(tag.id)),
          deleteIcon: const Icon(Icons.close_rounded, size: 17),
          backgroundColor: const Color(0xFFEAF9EF),
          side: BorderSide.none,
          visualDensity: VisualDensity.compact,
        ),
      OutlinedButton.icon(
        onPressed: _submitting ? null : _selectTags,
        icon: const Icon(Icons.sell_outlined, size: 19),
        label: Text(_selectedTagIds.isEmpty ? 'Add tags' : 'Edit tags'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _green,
          side: const BorderSide(color: Color(0xFFB8ECCA)),
          shape: const StadiumBorder(),
          visualDensity: VisualDensity.compact,
        ),
      ),
    ],
  );

  Future<void> _selectTags() async {
    if (_tags.isEmpty) {
      Get.snackbar('No tags available', 'Tags can be added by an administrator.');
      return;
    }
    final selected = {..._selectedTagIds};
    final saved = await Get.bottomSheet<Set<int>>(
      StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: SizedBox(width: 42, child: Divider(thickness: 4))),
                const SizedBox(height: 10),
                const Text('Add tags', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Choose tags that describe your post.', style: TextStyle(color: _muted, fontSize: 14)),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _tags.length,
                    itemBuilder: (context, index) {
                      final tag = _tags[index];
                      return CheckboxListTile(
                        value: selected.contains(tag.id),
                        onChanged: (checked) => setSheetState(() {
                          checked == true ? selected.add(tag.id) : selected.remove(tag.id);
                        }),
                        activeColor: _green,
                        contentPadding: EdgeInsets.zero,
                        title: Text(tag.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        subtitle: tag.description.isEmpty ? Text(tag.scope, style: const TextStyle(fontSize: 12)) : Text(tag.description, style: const TextStyle(fontSize: 12)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Get.back(result: selected),
                    style: FilledButton.styleFrom(backgroundColor: _green),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
    if (saved != null && mounted) {
      setState(() {
        _selectedTagIds
          ..clear()
          ..addAll(saved);
      });
    }
  }

  Widget _mediaCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(child: _mediaButton(Icons.image_outlined, 'Add images', () => _pick(ImageSource.gallery))),
            const SizedBox(width: 12),
            Expanded(child: _mediaButton(Icons.camera_alt_outlined, 'Take photo', () => _pick(ImageSource.camera))),
          ],
        ),
        const SizedBox(height: 18),
        _mediaPreview(),
      ],
    ),
  );

  Widget _mediaButton(IconData icon, String label, VoidCallback onPressed) => FilledButton.tonalIcon(
    onPressed: _submitting ? null : onPressed,
    icon: Icon(icon, color: _green, size: 22),
    label: Text(label, style: const TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w700)),
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFFF3F7F4),
      padding: const EdgeInsets.symmetric(vertical: 11),
      shape: const StadiumBorder(),
    ),
  );

  Widget _mediaPreview() {
    if (!_hasMedia) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFB8ECCA), style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 44, color: Color(0xFF737985)),
            SizedBox(height: 12),
            Text('No media added yet', style: TextStyle(color: _muted, fontSize: 16, fontWeight: FontWeight.w800)),
            SizedBox(height: 5),
            Text('Add up to 6 photos to bring your post to life', style: TextStyle(color: _muted, fontSize: 14)),
          ],
        ),
      );
    }
    final images = [
      ..._existingImageUrls.map((url) => Image.network(url, fit: BoxFit.cover)),
      ..._imageBytes.map((bytes) => Image.memory(bytes, fit: BoxFit.cover)),
    ];
    final existingCount = _existingImageUrls.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('$_imageCount of 6 images', style: const TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w700)),
            const Spacer(),
            if (existingCount > 0)
              TextButton(
                onPressed: _submitting ? null : () => setState(() => _removeExistingImage = true),
                child: const Text('Clear existing'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) => Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(14), child: images[index]),
              if (index >= existingCount)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: _submitting ? null : () => setState(
                        () => _imageBytes.removeAt(index - existingCount),
                      ),
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                      tooltip: 'Remove image',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingsCard() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: _cardDecoration(),
    child: Column(
      children: [
        _settingRow(
          icon: Icons.public_rounded,
          title: 'Audience',
          subtitle: 'Who can see this post',
          trailing: _audienceValue(),
          onTap: _openAudience,
        ),
        _settingRow(
          icon: Icons.mode_comment_outlined,
          title: 'Allow comments',
          subtitle: 'Others can comment on your post',
          trailing: Switch(
            value: _allowComments,
            activeThumbColor: Colors.white,
            activeTrackColor: _green,
            onChanged: _submitting
                ? null
                : (value) => setState(() => _allowComments = value),
          ),
        ),
      ],
    ),
  );

  Widget _settingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) => InkWell(
    onTap: _submitting ? null : onTap,
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: Color(0xFFEAF9EF), shape: BoxShape.circle),
            child: Icon(icon, color: _green, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: _muted, fontSize: 13)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    ),
  );

  Widget _audienceValue() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(_visibility.label, style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(width: 2),
      const Icon(Icons.chevron_right_rounded, color: _ink, size: 23),
    ],
  );

  Future<void> _openAudience() async {
    final selected = await Navigator.of(context).push<CommunityPostVisibility>(
      MaterialPageRoute(builder: (_) => _AudiencePage(selected: _visibility)),
    );
    if (selected != null && mounted) setState(() => _visibility = selected);
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(26),
    border: Border.all(color: const Color(0xFFE1E6E2)),
    boxShadow: const [BoxShadow(color: Color(0x09173D25), blurRadius: 14, offset: Offset(0, 4))],
  );

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.length == 1 ? parts.first[0].toUpperCase() : '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _AudiencePage extends StatefulWidget {
  const _AudiencePage({required this.selected});

  final CommunityPostVisibility selected;

  @override
  State<_AudiencePage> createState() => _AudiencePageState();
}

class _AudiencePageState extends State<_AudiencePage> {
  static const _green = Color(0xFF08A936);
  late CommunityPostVisibility _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFFEFF),
    appBar: AppBar(
      backgroundColor: const Color(0xFFFFFEFF),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 23),
        tooltip: 'Back',
      ),
      centerTitle: true,
      title: const Text('Audience', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
    ),
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
              children: [
                const Text('Who can see your post?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 7),
                const Text(
                  'Your post will show in Feed, on your profile, and in search results according to the audience you choose.',
                  style: TextStyle(color: Color(0xFF626A7A), fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 28),
                for (final audience in CommunityPostVisibility.values)
                  _option(audience, _subtitle(audience)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _option(CommunityPostVisibility audience, String subtitle) => InkWell(
    onTap: () => setState(() => _selected = audience),
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(color: Color(0xFFEAF9EF), shape: BoxShape.circle),
            child: Icon(audience.icon, color: _green, size: 25),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(audience.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Color(0xFF626A7A), fontSize: 13)),
              ],
            ),
          ),
          Radio<CommunityPostVisibility>(
            value: audience,
            groupValue: _selected,
            activeColor: _green,
            onChanged: (value) => setState(() => _selected = value!),
          ),
        ],
      ),
    ),
  );

  String _subtitle(CommunityPostVisibility audience) => switch (audience) {
    CommunityPostVisibility.public => 'Anyone using NhamHealth',
    CommunityPostVisibility.friends => 'People you are friends with',
    CommunityPostVisibility.onlyMe => 'Only you can see this post',
  };
}
