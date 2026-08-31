import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../theme/app_spacing.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/app_back_header.dart';
import '../../models/community/community_post.dart';
import '../../models/community/community_post_draft.dart';
import '../../models/community/community_tag.dart';
import '../../models/community/ingredient_suggestion.dart';
import '../../models/meals/meal_category_model.dart';
import '../../repositories/community/community_repository.dart';
import 'widgets/community_audience_picker.dart';

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
  static const _ingredientUnits = <String>[
    'g',
    'kg',
    'ml',
    'l',
    'tbsp',
    'tsp',
    'piece',
    'clove',
    'cup',
  ];
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _name, _description, _time, _servings;
  late List<_IngredientInput> _ingredients;
  final _newIngredient = _IngredientInput();
  List<IngredientSuggestion> _ingredientSuggestions = const [];
  Timer? _ingredientSearchDebounce;
  int _ingredientSearchVersion = 0;
  late List<TextEditingController> _steps;
  late List<String> _stepImageUrls;
  late List<Uint8List?> _stepImagePreviews;
  String _difficulty = 'EASY';
  Uint8List? _image;
  List<CommunityTag> _tags = const [];
  List<MealCategoryModel> _mealCategories = const [];
  late final Set<int> _selectedTags;
  int? _selectedCategoryId;
  bool _submitting = false;
  bool _tagsLoading = true;
  bool _categoriesLoading = true;
  bool _showValidation = false;
  bool _creatingTag = false;
  String? _tagsError;
  String? _categoriesError;
  late int _currentStep;
  late CommunityPostVisibility _visibility;

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
    // New recipe steps add a matching preview slot, so this must remain
    // growable. A fixed-length list fails on `.add`, leaving the step lists
    // out of sync and causing an out-of-range error while the editor rebuilds.
    _stepImagePreviews = List<Uint8List?>.filled(
      _steps.length,
      null,
      growable: true,
    );
    _selectedTags = {...?post?.tagIds};
    _selectedCategoryId = post?.categoryId;
    _currentStep = post == null ? 0 : 1;
    _visibility =
        post?.visibility == CommunityPostVisibility.followers
            ? CommunityPostVisibility.followers
            : CommunityPostVisibility.public;
    _loadTags();
    _loadMealCategories();
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

  Future<void> _loadMealCategories() async {
    if (mounted) {
      setState(() {
        _categoriesLoading = true;
        _categoriesError = null;
      });
    }
    try {
      final value = await Get.find<CommunityRepository>().getMealCategories();
      if (mounted) setState(() => _mealCategories = value);
    } on Object catch (error) {
      if (mounted) setState(() => _categoriesError = error.toString());
    } finally {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  @override
  void dispose() {
    _ingredientSearchDebounce?.cancel();
    _name.dispose();
    _description.dispose();
    _time.dispose();
    _servings.dispose();
    for (final item in _ingredients) {
      item.dispose();
    }
    _newIngredient.dispose();
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
    if (_selectedCategoryId == null) {
      Get.snackbar('Select a category', 'Choose a meal category before publishing.');
      return;
    }
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
          visibility: _visibility,
          allowComments: true,
          allowReplies: true,
          tagIds: _selectedTags.toList(),
          categoryId: _selectedCategoryId,
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
    if (_selectedCategoryId == null) {
      Get.snackbar('Select a category', 'Choose a meal category before continuing.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _showValidation = false;
      _currentStep = 1;
    });
  }

  void _addIngredient() {
    final name = _newIngredient.name.text.trim();
    final amount = num.tryParse(_newIngredient.amount.text.trim());
    if (name.isEmpty || amount == null || amount <= 0) {
      Get.snackbar(
        'Add ingredient details',
        'Enter an ingredient name and a valid amount first.',
      );
      return;
    }
    _ingredientSearchDebounce?.cancel();
    _ingredientSearchVersion++;
    setState(() {
      _ingredients.add(
        _IngredientInput(
          name: name,
          amount: _newIngredient.amount.text.trim(),
          unit: _newIngredient.unit,
        ),
      );
      _newIngredient.name.clear();
      _newIngredient.amount.clear();
      _newIngredient.unit = 'g';
      _ingredientSuggestions = const [];
    });
    FocusScope.of(context).unfocus();
  }

  void _searchIngredients(String rawQuery) {
    _ingredientSearchDebounce?.cancel();
    final query = rawQuery.trim();
    final requestVersion = ++_ingredientSearchVersion;
    if (query.isEmpty) {
      setState(() => _ingredientSuggestions = const []);
      return;
    }
    setState(() => _ingredientSuggestions = const []);
    _ingredientSearchDebounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        final results = await Get.find<CommunityRepository>().searchIngredients(query);
        if (mounted && requestVersion == _ingredientSearchVersion) {
          setState(() => _ingredientSuggestions = results);
        }
      } on Object {
        // A temporary search failure should never prevent someone entering an
        // ingredient manually.
      }
    });
  }

  void _selectIngredient(IngredientSuggestion ingredient) {
    setState(() {
      _newIngredient.name.text = ingredient.name;
      if (_ingredientUnits.contains(ingredient.defaultUnit)) {
        _newIngredient.unit = ingredient.defaultUnit;
      }
      _ingredientSuggestions = const [];
    });
    FocusScope.of(context).unfocus();
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
    backgroundColor: Colors.transparent,
    body: AppBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: AppSpacing.topBarPagePadding,
              child: AppBackHeader(
                title: widget.post == null ? 'Create Meal' : 'Edit Meal',
                onBack:
                    _currentStep == 0
                        ? () => Navigator.maybePop(context)
                        : () => setState(() => _currentStep = 0),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Form(
                key: _formKey,
                autovalidateMode:
                    _showValidation
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                child: ListView(
                  key: ValueKey(_currentStep),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    _progressHeader(),
                    const SizedBox(height: 18),
                    if (_currentStep == 0)
                      ..._basicInfoFields()
                    else
                      ..._recipeFields(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE7ECE8))),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          onPressed:
              _submitting
                  ? null
                  : _currentStep == 0
                  ? _continueToRecipe
                  : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: green,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size.fromHeight(50),
            padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _progressHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _progressStep(
        1,
        'Basic Info',
        isActive: _currentStep == 0,
        isComplete: _currentStep == 1,
      ),
      Expanded(
        child: Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          color:
              _currentStep == 1
                  ? const Color(0xFF9BCFB0)
                  : const Color(0xFFE0E6E2),
        ),
      ),
      _progressStep(
        2,
        'Ingredients & Steps',
        isActive: _currentStep == 1,
      ),
    ],
  );

  Widget _progressStep(
    int number,
    String label, {
    required bool isActive,
    bool isComplete = false,
  }) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              isActive
                  ? green
                  : isComplete
                  ? const Color(0xFFE5F7EC)
                  : const Color(0xFFF1F3F2),
        ),
        child:
            isComplete
                ? const Icon(Icons.check_rounded, size: 14, color: green)
                : Text(
                  '$number',
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF89928C),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
      ),
      const SizedBox(width: 7),
      Text(
        label,
        style: TextStyle(
          color: isActive ? const Color(0xFF2B6242) : const Color(0xFF7B847E),
          fontSize: 11,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ],
  );

  List<Widget> _basicInfoFields() => [
    InkWell(
      onTap: _submitting ? null : _chooseImage,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 174,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FCF9), Color(0xFFE6F7EC)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC5E6D0)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _image != null
                ? Image.memory(_image!, fit: BoxFit.cover)
                : widget.post?.imageUrl.isNotEmpty == true
                ? Image.network(widget.post!.imageUrl, fit: BoxFit.cover)
                : _emptyPhotoPrompt(),
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
    const SizedBox(height: 18),
    _field(
      _name,
      'Meal name',
      hint: 'Khmer Fish Amok',
      icon: Icons.restaurant_menu_rounded,
      validator:
          (v) =>
              v == null || v.trim().isEmpty ? 'Meal name is required.' : null,
    ),
    _field(
      _description,
      'Description',
      hint: 'Tell people about this meal',
      icon: Icons.subject_rounded,
      lines: 2,
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
            icon: Icons.schedule_rounded,
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
            icon: Icons.group_outlined,
            keyboard: TextInputType.number,
            validator: (v) => _positive(v, 'Servings'),
          ),
        ),
      ],
    ),
    const Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFFEAF8EF),
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 22,
            height: 22,
            child: Icon(Icons.tune_rounded, color: green, size: 13),
          ),
        ),
        SizedBox(width: 7),
        Text(
          'Difficulty',
          style: TextStyle(
            color: Color(0xFF334139),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE5DF)),
      ),
      child: Row(
        children: [
          _difficultyCard('EASY', Icons.sentiment_satisfied_alt_rounded),
          const SizedBox(width: 4),
          _difficultyCard('MEDIUM', Icons.sentiment_neutral_rounded),
          const SizedBox(width: 4),
          _difficultyCard('HARD', Icons.sentiment_dissatisfied_rounded),
        ],
      ),
    ),
    const SizedBox(height: 16),
    _mealCategoryField(),
  ];

  Widget _emptyPhotoPrompt() => Stack(
    children: [
      Positioned(
        top: 13,
        left: 14,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .82),
            borderRadius: BorderRadius.circular(99),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, color: green, size: 15),
              SizedBox(width: 5),
              Text(
                'Cover photo',
                style: TextStyle(
                  color: Color(0xFF2B6242),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
      const Positioned(
        top: 19,
        right: 16,
        child: Text(
          'Recommended',
          style: TextStyle(color: Color(0xFF718078), fontSize: 11),
        ),
      ),
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x19056E38),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(Icons.add_a_photo_outlined, color: green, size: 27),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a delicious photo',
              style: TextStyle(color: Color(0xFF17643A), fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            const Text(
              'A clear photo helps your meal stand out',
              style: TextStyle(color: Color(0xFF637169), fontSize: 12),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _mealCategoryField() {
    if (_categoriesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (_categoriesError != null) {
      return _inlineError('Meal categories could not be loaded.', _loadMealCategories);
    }
    MealCategoryModel? selectedCategory;
    for (final category in _mealCategories) {
      if (category.id == _selectedCategoryId) {
        selectedCategory = category;
        break;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Meal category', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: selectedCategory == null
                    ? const Color(0xFFF7F9F7)
                    : const Color(0xFFEAF8EF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selectedCategory == null
                      ? const Color(0xFFDCE5DF)
                      : green,
                ),
              ),
              child: InkWell(
                onTap: _submitting ? null : _showMealCategoryPicker,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: selectedCategory == null ? Colors.white : green,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _mealCategoryIcon(selectedCategory?.name ?? ''),
                          color: selectedCategory == null ? green : Colors.white,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedCategory?.name ?? 'Choose a category',
                              style: TextStyle(
                                color: selectedCategory == null
                                    ? const Color(0xFF526158)
                                    : const Color(0xFF145C35),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedCategory == null
                                  ? 'Select where your meal belongs'
                                  : 'Tap to change',
                              style: const TextStyle(
                                color: Color(0xFF718078),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF526158),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_showValidation && _selectedCategoryId == null)
            const Padding(
              padding: EdgeInsets.only(top: 6, left: 12),
              child: Text(
                'Select a meal category.',
                style: TextStyle(color: Color(0xFFCF3B3B), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showMealCategoryPicker() async {
    final categoryId = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .65,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9AA19C),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose meal category',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'This is where your meal will appear after approval.',
                  style: TextStyle(color: Color(0xFF718078), fontSize: 13),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _mealCategories.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final category = _mealCategories[index];
                      final selected = category.id == _selectedCategoryId;
                      return Material(
                        color: selected ? const Color(0xFFEAF8EF) : const Color(0xFFF7F9F7),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.pop(sheetContext, category.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: selected ? green : Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _mealCategoryIcon(category.name),
                                    color: selected ? Colors.white : green,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    category.name,
                                    style: TextStyle(
                                      color: const Color(0xFF18231C),
                                      fontSize: 15,
                                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  const Icon(Icons.check_circle_rounded, color: green),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (categoryId != null && mounted) {
      setState(() => _selectedCategoryId = categoryId);
    }
  }

  IconData _mealCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('breakfast') || name.contains('brunch')) return Icons.egg_alt_rounded;
    if (name.contains('snack') || name.contains('dessert')) return Icons.bakery_dining_rounded;
    if (name.contains('beverage') || name.contains('drink')) return Icons.local_drink_rounded;
    if (name.contains('appetizer')) return Icons.tapas_rounded;
    if (name.contains('late')) return Icons.nightlight_round;
    if (name.contains('lunch') || name.contains('dinner')) return Icons.dinner_dining_rounded;
    return Icons.restaurant_rounded;
  }

  List<Widget> _recipeFields() => [
    _heading(
      'Ingredients',
      'Search a food, then add the amount you used.',
      Icons.shopping_basket_outlined,
    ),
    _ingredientComposer(),
    const SizedBox(height: 16),
    _ingredientList(),
    _heading(
      'How to Cook',
      'Keep each instruction short and clear.',
      Icons.restaurant_menu_rounded,
    ),
    ...List.generate(_steps.length, _stepCard),
    _addButton(
      'Add step',
      () => setState(() {
        _steps.add(TextEditingController());
        _stepImageUrls.add('');
        _stepImagePreviews.add(null);
      }),
    ),
    _heading('Tags', 'Help people discover your meal.', Icons.sell_outlined),
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
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    side: const BorderSide(color: Color(0xFFB9DFC7)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onSelected: (_) => setState(() => _selectedTags.remove(tag.id)),
                  ),
                )
                .toList(),
      ),
      const SizedBox(height: 10),
      _addButton('Add tags', _showTagPicker),
    ],
    _heading(
      'Post audience',
      'Choose who can see your meal.',
      Icons.visibility_outlined,
    ),
    _audienceField(),
  ];

  Widget _audienceField() => Material(
    color: const Color(0xFFF7FAF8),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      key: const ValueKey<String>('community-post-audience'),
      borderRadius: BorderRadius.circular(16),
      onTap: _submitting
          ? null
          : () async {
              final selected = await showCommunityAudiencePicker(
                context,
                selected: _visibility,
              );
              if (selected != null && mounted) {
                setState(() => _visibility = selected);
              }
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFDDF4E5),
                shape: BoxShape.circle,
              ),
              child: Icon(_visibility.icon, color: green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _visibility.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _visibility.description,
                    style: const TextStyle(
                      color: Color(0xFF718078),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF718078)),
          ],
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    String? suffix,
    IconData? icon,
    int lines = 1,
    int? maxLength,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF8EF),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: green, size: 13),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF334139),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
        fillColor: const Color(0xFFFFFEFF),
        hintStyle: const TextStyle(color: Color(0xFF909A94)),
        suffixStyle: const TextStyle(color: Color(0xFF617068), fontWeight: FontWeight.w600),
        counterStyle: const TextStyle(color: Color(0xFF7B847E), fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDE5DF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDE5DF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCF3B3B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCF3B3B), width: 1.5),
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
  Widget _heading(String title, String subtitle, IconData icon) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFFE7F6EC),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: green),
            ),
            const SizedBox(width: 9),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: Color(0xFF718078))),
      ],
    ),
  );
  Widget _addButton(String label, VoidCallback action) => Opacity(
    opacity: _submitting ? .55 : 1,
    child: Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF1FBF5), Color(0xFFE2F6E9)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFB8DEC6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12056E38),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: InkWell(
          onTap: _submitting ? null : action,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFF17643A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Keep your recipe clear and easy to follow',
                        style: TextStyle(
                          color: Color(0xFF62816D),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF3B885B),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _difficultyCard(String value, IconData icon) {
    final selected = _difficulty == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _difficulty = value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 42,
          decoration: BoxDecoration(
            color: selected ? green : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x26056E38),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : const Color(0xFF728078),
              ),
              const SizedBox(width: 5),
              Text(
                value[0] + value.substring(1).toLowerCase(),
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF526158),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ingredientComposer() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF2FBF5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFD7EBDE)),
    ),
    child: Column(
      children: [
        TextFormField(
          controller: _newIngredient.name,
          onChanged: _searchIngredients,
          decoration: _decoration(
            hint: 'Search ingredient catalog',
          ).copyWith(
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
          ),
          textInputAction: TextInputAction.next,
        ),
        if (_ingredientSuggestions.isNotEmpty) ...[
          const SizedBox(height: 7),
          _ingredientSuggestionPanel(),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _newIngredient.amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _decoration(hint: 'Amount'),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _addIngredient(),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 96,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _newIngredient.unit,
                items:
                    _ingredientUnits
                        .map(
                          (unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit),
                          ),
                        )
                        .toList(),
                onChanged:
                    (value) => setState(() => _newIngredient.unit = value!),
                decoration: _decoration(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _submitting ? null : _addIngredient,
            icon: const Icon(Icons.playlist_add_rounded, size: 20),
            label: const Text('Add ingredient to list'),
            style: FilledButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(46),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _ingredientSuggestionPanel() => Container(
    constraints: const BoxConstraints(maxHeight: 180),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFB9DFC7)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1600331B),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _ingredientSuggestions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final ingredient = _ingredientSuggestions[index];
        return ListTile(
          dense: true,
          leading: const Icon(
            Icons.restaurant_rounded,
            color: green,
            size: 20,
          ),
          title: Text(ingredient.name),
          trailing:
              ingredient.defaultUnit.isEmpty
                  ? null
                  : Text(
                    ingredient.defaultUnit,
                    style: const TextStyle(color: Color(0xFF718078)),
                  ),
          onTap: () => _selectIngredient(ingredient),
        );
      },
    ),
  );

  Widget _ingredientList() {
    if (_ingredients.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E9E4)),
        ),
        child: const Text(
          'No ingredients added yet',
          style: TextStyle(color: Color(0xFF718078)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            'Ingredients list',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E9E4)),
          ),
          child: Column(
            children: List.generate(_ingredients.length, (index) {
              final item = _ingredients[index];
              return Column(
                children: [
                  _ingredientListRow(index, item),
                  if (index < _ingredients.length - 1)
                    const Divider(height: 1, color: Color(0xFFEDF1EE)),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _ingredientListRow(int index, _IngredientInput item) => SizedBox(
    height: 44,
    child: Row(
      children: [
        const SizedBox(width: 10),
        const Icon(
          Icons.drag_indicator_rounded,
          size: 17,
          color: Color(0xFFA5AFA8),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            item.name.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        SizedBox(
          width: 38,
          child: Text(
            item.amount.text,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        SizedBox(
          width: 42,
          child: Text(
            item.unit,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xFF637169)),
          ),
        ),
        IconButton(
          tooltip: 'Remove ${item.name.text}',
          visualDensity: VisualDensity.compact,
          onPressed: () {
            item.dispose();
            setState(() => _ingredients.removeAt(index));
          },
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          color: const Color(0xFF65716A),
        ),
        const SizedBox(width: 2),
      ],
    ),
  );

  Widget _stepCard(int index) => Card(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFDDE9E1)),
    ),
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(12),
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
