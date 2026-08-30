import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/community/community_post.dart';
import '../../models/community/community_post_draft.dart';
import '../../models/community/community_tag.dart';
import '../../repositories/community/community_repository.dart';

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
  State<CommunityPostEditorPage> createState() =>
      _CommunityPostEditorPageState();
}

class _CommunityPostEditorPageState extends State<CommunityPostEditorPage> {
  static const green = Color(0xFF0AAA55);
  static const _ingredientSuggestions = <String>[
    'Fish (Catfish)',
    'Coconut milk',
    'Kroeung (Khmer spice paste)',
    'Palm sugar',
    'Fish sauce',
    'Chicken breast',
    'Brown rice',
    'Garlic',
    'Ginger',
    'Lime',
  ];
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _name, _description, _time, _servings;
  late List<_IngredientInput> _ingredients;
  late List<TextEditingController> _steps;
  late List<String> _stepImageUrls;
  late List<Uint8List?> _stepImagePreviews;
  String _difficulty = 'EASY';
  Uint8List? _image;
  List<CommunityTag> _tags = const [];
  late final Set<int> _selectedTags;
  bool _submitting = false;
  bool _tagsLoading = true;
  bool _showValidation = false;
  bool _creatingTag = false;
  String? _tagsError;
  late int _currentStep;

  @override
  void initState() {
    super.initState();
    final post = widget.post;
    _name = TextEditingController(text: post?.mealName ?? '');
    _description = TextEditingController(text: post?.description ?? '');
    _time = TextEditingController(
      text: post?.cookingTimeMinutes?.toString() ?? '',
    );
    _servings = TextEditingController(text: post?.servings?.toString() ?? '');
    _difficulty =
        post?.difficulty.isNotEmpty == true
            ? post!.difficulty.toUpperCase()
            : 'EASY';
    _ingredients =
        (post?.ingredients ?? const <MealPostIngredient>[])
            .map(_IngredientInput.fromModel)
            .toList();
    if (_ingredients.isEmpty) _ingredients.add(_IngredientInput());
    _steps =
        (post?.steps ?? const <MealPostStep>[])
            .map((item) => TextEditingController(text: item.instruction))
            .toList();
    if (_steps.isEmpty) _steps.add(TextEditingController());
    _stepImageUrls =
        (post?.steps ?? const <MealPostStep>[])
            .map((step) => step.imageUrl)
            .toList();
    while (_stepImageUrls.length < _steps.length) {
      _stepImageUrls.add('');
    }
    _stepImagePreviews = List<Uint8List?>.filled(_steps.length, null);
    _selectedTags = {...?post?.tagIds};
    _currentStep = post == null ? 0 : 1;
    _loadTags();
  }

  Future<void> _loadTags() async {
    if (mounted) {
      setState(() {
        _tagsLoading = true;
        _tagsError = null;
      });
    }
    try {
      final value = await Get.find<CommunityRepository>().getTags();
      if (mounted) setState(() => _tags = value);
    } on Object catch (error) {
      if (mounted) setState(() => _tagsError = error.toString());
    } finally {
      if (mounted) setState(() => _tagsLoading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _time.dispose();
    _servings.dispose();
    for (final item in _ingredients) {
      item.dispose();
    }
    for (final item in _steps) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => _image = bytes);
  }

  Future<void> _chooseImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add a meal photo',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text('Choose from gallery'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: const Text('Take a photo'),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                ],
              ),
            ),
          ),
    );
    if (source != null) await _pickImage(source);
  }

  String? _positive(String? value, String label) =>
      (int.tryParse(value?.trim() ?? '') ?? 0) > 0
          ? null
          : '$label must be greater than 0.';

  Future<void> _submit() async {
    setState(() => _showValidation = true);
    if (!_formKey.currentState!.validate()) return;
    final ingredients =
        _ingredients
            .where((item) => item.name.text.trim().isNotEmpty)
            .map(
              (item) => MealPostIngredient(
                ingredientName: item.name.text.trim(),
                amount: num.tryParse(item.amount.text.trim()),
                unit: item.unit,
              ),
            )
            .toList();
    final steps = _steps.where((item) => item.text.trim().isNotEmpty).toList();
    if (ingredients.isEmpty) {
      Get.snackbar('Recipe incomplete', 'Add at least one ingredient.');
      return;
    }
    if (ingredients.any((item) => item.amount == null || item.amount! <= 0)) {
      Get.snackbar(
        'Recipe incomplete',
        'Every ingredient needs a valid amount.',
      );
      return;
    }
    if (steps.isEmpty) {
      Get.snackbar('Recipe incomplete', 'Add at least one cooking step.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        CommunityPostDraft(
          mealName: _name.text.trim(),
          description: _description.text.trim(),
          cookingTimeMinutes: int.parse(_time.text),
          servings: int.parse(_servings.text),
          difficulty: _difficulty,
          ingredients: ingredients,
          steps: List.generate(
            steps.length,
            (index) => MealPostStep(
              stepNumber: index + 1,
              instruction: steps[index].text.trim(),
              imageUrl: _stepImageUrls[_steps.indexOf(steps[index])],
            ),
          ),
          imageBytes: _image == null ? const [] : [_image!],
          removeImage: false,
          visibility: CommunityPostVisibility.public,
          allowComments: true,
          allowReplies: true,
          tagIds: _selectedTags.toList(),
        ),
      );
      if (mounted) Get.back(result: true);
    } on Object catch (error) {
      Get.snackbar('Could not publish meal', error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickStepImage(int index) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => _stepImagePreviews[index] = bytes);
    try {
      final url = await Get.find<CommunityRepository>().uploadStepImage(bytes);
      if (mounted) setState(() => _stepImageUrls[index] = url);
    } on Object catch (error) {
      if (mounted) setState(() => _stepImagePreviews[index] = null);
      Get.snackbar('Could not upload image', error.toString());
    }
  }

  void _continueToRecipe() {
    setState(() => _showValidation = true);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _showValidation = false;
      _currentStep = 1;
    });
  }

  Future<void> _createAndSelectTag(
    String name,
    StateSetter updateSheet,
  ) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty || _creatingTag) return;
    updateSheet(() => _creatingTag = true);
    try {
      final tag = await Get.find<CommunityRepository>().createTag(cleanName);
      if (!mounted) return;
      setState(() {
        if (!_tags.any((item) => item.id == tag.id)) {
          _tags = [..._tags, tag]..sort((a, b) => a.name.compareTo(b.name));
        }
        _selectedTags.add(tag.id);
      });
      updateSheet(() {});
    } on Object catch (error) {
      Get.snackbar('Could not create tag', error.toString());
    } finally {
      _creatingTag = false;
      updateSheet(() {});
    }
  }

  Future<void> _showTagPicker() async {
    final search = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (sheetContext) => StatefulBuilder(
            builder: (context, updateSheet) {
              final query = search.text.trim().toLowerCase();
              final visible = _tags
                  .where((tag) => tag.name.toLowerCase().contains(query))
                  .toList(growable: false);
              final exactMatch = _tags.any(
                (tag) => tag.name.toLowerCase() == query,
              );
              final mealName = _name.text.trim();
              final hasMealNameTag = _tags.any(
                (tag) => tag.name.toLowerCase() == mealName.toLowerCase(),
              );
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    MediaQuery.viewInsetsOf(context).bottom + 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 520),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add meal tags',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Choose a tag, create your own, or use the food name.',
                          style: TextStyle(color: Color(0xFF718078)),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: search,
                          autofocus: true,
                          onChanged: (_) => updateSheet(() {}),
                          decoration: _decoration(
                            hint: 'Search tags',
                          ).copyWith(
                            prefixIcon: const Icon(Icons.search_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Flexible(
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              ...visible.map(
                                (tag) => CheckboxListTile(
                                  value: _selectedTags.contains(tag.id),
                                  activeColor: green,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(tag.name),
                                  onChanged: (selected) {
                                    setState(
                                      () =>
                                          selected == true
                                              ? _selectedTags.add(tag.id)
                                              : _selectedTags.remove(tag.id),
                                    );
                                    updateSheet(() {});
                                  },
                                ),
                              ),
                              if (query.isEmpty &&
                                  mealName.isNotEmpty &&
                                  !hasMealNameTag)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFE5F7EC),
                                    child: Icon(
                                      Icons.restaurant_menu_rounded,
                                      color: green,
                                    ),
                                  ),
                                  title: Text('Use food name: "$mealName"'),
                                  subtitle: const Text('Create and select tag'),
                                  onTap:
                                      _creatingTag
                                          ? null
                                          : () => _createAndSelectTag(
                                            mealName,
                                            updateSheet,
                                          ),
                                ),
                              if (query.isNotEmpty && !exactMatch)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFE5F7EC),
                                    child: Icon(Icons.add_rounded, color: green),
                                  ),
                                  title: Text('Create "${search.text.trim()}"'),
                                  subtitle: const Text('Create and select tag'),
                                  trailing:
                                      _creatingTag
                                          ? const SizedBox.square(
                                            dimension: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : null,
                                  onTap:
                                      _creatingTag
                                          ? null
                                          : () => _createAndSelectTag(
                                            search.text,
                                            updateSheet,
                                          ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: FilledButton.styleFrom(
                              backgroundColor: green,
                            ),
                            child: const Text('Done'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
    search.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F8F6),
    appBar: AppBar(
      leading: IconButton(
        onPressed:
            _currentStep == 0
                ? () => Navigator.maybePop(context)
                : () => setState(() => _currentStep = 0),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 21),
      ),
      title: Text(widget.post == null ? 'Create Meal' : 'Edit Meal'),
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.white,
    ),
    body: Form(
      key: _formKey,
      autovalidateMode:
          _showValidation
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
      child: ListView(
        key: ValueKey(_currentStep),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          _progressHeader(),
          const SizedBox(height: 26),
          if (_currentStep == 0) ..._basicInfoFields() else ..._recipeFields(),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: FilledButton(
          onPressed:
              _submitting
                  ? null
                  : _currentStep == 0
                  ? _continueToRecipe
                  : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: green,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child:
              _submitting
                  ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentStep == 0
                            ? 'Next: Ingredients'
                            : widget.post == null
                            ? 'Publish Meal'
                            : 'Save Changes',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
        ),
      ),
    ),
  );

  Widget _progressHeader() {
    final title = _currentStep == 0 ? 'Basic Info' : 'Ingredients & Steps';
    final subtitle =
        _currentStep == 0
            ? 'Tell us about your meal'
            : 'Add details so others can cook it';
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF1FBF5),
                border: Border.all(color: green, width: 2),
              ),
              child: Text(
                '${_currentStep + 1}/2',
                style: const TextStyle(
                  color: green,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF758078)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 2,
            minHeight: 4,
            color: green,
            backgroundColor: const Color(0xFFE8EBE9),
          ),
        ),
      ],
    );
  }

  List<Widget> _basicInfoFields() => [
    InkWell(
      onTap: _submitting ? null : _chooseImage,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 210,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5EC),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFCFE4D5)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _image != null
                ? Image.memory(_image!, fit: BoxFit.cover)
                : widget.post?.imageUrl.isNotEmpty == true
                ? Image.network(widget.post!.imageUrl, fit: BoxFit.cover)
                : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: green, size: 34),
                    SizedBox(height: 8),
                    Text(
                      'Add meal photo',
                      style: TextStyle(
                        color: green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Use a bright, clear photo',
                      style: TextStyle(color: Color(0xFF637169)),
                    ),
                  ],
                ),
            if (_image != null || widget.post?.imageUrl.isNotEmpty == true)
              Positioned(
                right: 12,
                bottom: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .62),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Change photo',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 22),
    _field(
      _name,
      'Meal name',
      hint: 'Khmer Fish Amok',
      validator:
          (v) =>
              v == null || v.trim().isEmpty ? 'Meal name is required.' : null,
    ),
    _field(
      _description,
      'Description',
      hint: 'Tell people about this meal',
      lines: 3,
      maxLength: 4000,
    ),
    Row(
      children: [
        Expanded(
          child: _field(
            _time,
            'Cooking time',
            hint: '45',
            suffix: 'min',
            keyboard: TextInputType.number,
            validator: (v) => _positive(v, 'Cooking time'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _field(
            _servings,
            'Servings',
            hint: '2',
            keyboard: TextInputType.number,
            validator: (v) => _positive(v, 'Servings'),
          ),
        ),
      ],
    ),
    const Text('Difficulty', style: TextStyle(fontWeight: FontWeight.w700)),
    const SizedBox(height: 7),
    const SizedBox(height: 8),
    Row(
      children: [
        _difficultyCard('EASY', Icons.sentiment_satisfied_alt_rounded),
        const SizedBox(width: 10),
        _difficultyCard('MEDIUM', Icons.sentiment_neutral_rounded),
        const SizedBox(width: 10),
        _difficultyCard('HARD', Icons.sentiment_dissatisfied_rounded),
      ],
    ),
  ];

  List<Widget> _recipeFields() => [
    _heading('Ingredients', 'Add exact amounts so others can cook it.'),
    ...List.generate(_ingredients.length, _ingredientCard),
    _addButton(
      'Add ingredient',
      () => setState(() => _ingredients.add(_IngredientInput())),
    ),
    _heading('How to Cook', 'Keep each instruction short and clear.'),
    ...List.generate(_steps.length, _stepCard),
    _addButton(
      'Add step',
      () => setState(() {
        _steps.add(TextEditingController());
        _stepImageUrls.add('');
        _stepImagePreviews.add(null);
      }),
    ),
    _heading('Tags', 'Help people discover your meal.'),
    if (_tagsLoading)
      const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      )
    else if (_tagsError != null)
      _inlineError('Tags could not be loaded.', _loadTags)
    else ...[
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            _tags
                .where((tag) => _selectedTags.contains(tag.id))
                .map(
                  (tag) => FilterChip(
                    label: Text(tag.name),
                    selected: true,
                    selectedColor: const Color(0xFFDDF5E6),
                    checkmarkColor: green,
                    onSelected: (_) => setState(() => _selectedTags.remove(tag.id)),
                  ),
                )
                .toList(),
      ),
      const SizedBox(height: 10),
      _addButton('Add tags', _showTagPicker),
    ],
  ];

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    String? suffix,
    int lines = 1,
    int? maxLength,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          maxLines: lines,
          maxLength: maxLength,
          keyboardType: keyboard,
          validator: validator,
          decoration: _decoration(hint: hint, suffix: suffix),
        ),
      ],
    ),
  );
  InputDecoration _decoration({String? hint, String? suffix}) =>
      InputDecoration(
        hintText: hint,
        suffixText: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDE5DF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDE5DF)),
        ),
      );

  Widget _inlineError(String message, VoidCallback retry) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4E5),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_outlined, color: Color(0xFF8A5700)),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
        TextButton(onPressed: retry, child: const Text('Retry')),
      ],
    ),
  );
  Widget _heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: Color(0xFF718078))),
      ],
    ),
  );
  Widget _addButton(String label, VoidCallback action) => OutlinedButton.icon(
    onPressed: _submitting ? null : action,
    icon: const Icon(Icons.add_rounded),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor: green,
      side: const BorderSide(color: Color(0xFFB9DFC7)),
      padding: const EdgeInsets.symmetric(vertical: 13),
    ),
  );

  Widget _difficultyCard(String value, IconData icon) {
    final selected = _difficulty == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _difficulty = value),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 94,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF2FBF5) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? green : const Color(0xFFDDE5DF),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? green : const Color(0xFF858D88)),
              const SizedBox(height: 7),
              Text(
                value[0] + value.substring(1).toLowerCase(),
                style: TextStyle(
                  color: selected ? green : const Color(0xFF29302C),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ingredientCard(int index) {
    final item = _ingredients[index];
    return Card(
      color: const Color(0xFFF0FAF3),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Ingredient ${index + 1}',
                  style: const TextStyle(
                    color: green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (_ingredients.length > 1)
                  IconButton(
                    onPressed: () {
                      item.dispose();
                      setState(() => _ingredients.removeAt(index));
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                  ),
              ],
            ),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: item.name.text),
              optionsBuilder: (value) {
                final query = value.text.trim().toLowerCase();
                if (query.isEmpty) return const Iterable<String>.empty();
                return _ingredientSuggestions.where(
                  (name) => name.toLowerCase().contains(query),
                );
              },
              onSelected: (value) => item.name.text = value,
              fieldViewBuilder:
                  (context, controller, focusNode, onSubmit) => TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: (value) => item.name.text = value,
                    decoration: _decoration(
                      hint: 'Search ingredient',
                    ).copyWith(prefixIcon: const Icon(Icons.search_rounded)),
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty
                                ? 'Ingredient is required.'
                                : null,
                  ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _decoration(hint: 'Amount'),
                    validator:
                        (v) =>
                            num.tryParse(v ?? '') == null
                                ? 'Amount is required.'
                                : null,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 105,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: item.unit,
                    items:
                        const [
                              'g',
                              'kg',
                              'ml',
                              'l',
                              'tbsp',
                              'tsp',
                              'piece',
                              'clove',
                              'cup',
                            ]
                            .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)),
                            )
                            .toList(),
                    onChanged: (v) => item.unit = v!,
                    decoration: _decoration(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepCard(int index) => Card(
    color: const Color(0xFFF0FAF3),
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: green,
            child: Text(
              '${index + 1}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                TextFormField(
                  controller: _steps[index],
                  minLines: 2,
                  maxLines: 4,
                  decoration: _decoration(
                    hint: 'Describe this cooking step',
                  ).copyWith(
                    suffixIcon: IconButton(
                      tooltip: 'Add step photo',
                      onPressed: () => _pickStepImage(index),
                      icon: Icon(
                        _stepImageUrls[index].isEmpty
                            ? Icons.add_photo_alternate_outlined
                            : Icons.check_circle_rounded,
                        color: green,
                      ),
                    ),
                  ),
                  validator:
                      (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Instruction is required.'
                              : null,
                ),
                if (_stepImagePreviews[index] != null ||
                    _stepImageUrls[index].isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 90,
                      width: double.infinity,
                      child:
                          _stepImagePreviews[index] != null
                              ? Image.memory(
                                _stepImagePreviews[index]!,
                                fit: BoxFit.cover,
                              )
                              : Image.network(
                                _stepImageUrls[index],
                                fit: BoxFit.cover,
                              ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_steps.length > 1)
            IconButton(
              onPressed: () {
                _steps[index].dispose();
                setState(() {
                  _steps.removeAt(index);
                  _stepImageUrls.removeAt(index);
                  _stepImagePreviews.removeAt(index);
                });
              },
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
        ],
      ),
    ),
  );
}

class _IngredientInput {
  _IngredientInput({String name = '', String amount = '', this.unit = 'g'})
    : name = TextEditingController(text: name),
      amount = TextEditingController(text: amount);
  factory _IngredientInput.fromModel(MealPostIngredient value) =>
      _IngredientInput(
        name: value.ingredientName,
        amount: value.amount?.toString() ?? '',
        unit: value.unit.isEmpty ? 'g' : value.unit,
      );
  final TextEditingController name, amount;
  String unit;
  void dispose() {
    name.dispose();
    amount.dispose();
  }
}
