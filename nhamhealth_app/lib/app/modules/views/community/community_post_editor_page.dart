import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/auth_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/app_back_header.dart';
import '../../models/community/community_post.dart';
import '../../models/community/community_post_draft.dart';
import '../../models/community/community_tag.dart';
import '../../models/community/ingredient_suggestion.dart';
import '../../models/favorites/favorite_food.dart';
import '../../models/meals/meal_category_model.dart';
import '../../providers/favorites/favorites_provider.dart';
import '../../repositories/community/community_repository.dart';
import '../../repositories/favorites/favorites_repository.dart';

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
  // Keep the established app green for primary actions and selected states.
  // The surrounding pale surfaces provide the visual softness.
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
  late final TextEditingController _name, _time, _servings;
  late List<_IngredientInput> _ingredients;
  final _newIngredient = _IngredientInput();
  List<IngredientSuggestion> _ingredientSuggestions = const [];
  Timer? _ingredientSearchDebounce;
  int _ingredientSearchVersion = 0;
  late List<TextEditingController> _steps;
  final _newStep = TextEditingController();
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
  FavoriteFood? _selectedFavoriteFood;
  String? _tagsError;
  String? _categoriesError;
  late int _currentStep;
  late CommunityPostVisibility _visibility;

  @override
  void initState() {
    super.initState();
    final post = widget.post;
    _name = TextEditingController(text: post?.mealName ?? '');
    _time = TextEditingController(
      text: post?.cookingTimeMinutes?.toString() ?? '',
    );
    _servings = TextEditingController(text: post?.servings?.toString() ?? '');
    _name.addListener(_refreshBasicInfoState);
    _time.addListener(_refreshBasicInfoState);
    _servings.addListener(_refreshBasicInfoState);
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
    _selectedTags = {...?post?.tagIds};
    _selectedCategoryId = post?.categoryId;
    _currentStep = 0;
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
      if (mounted) {
        setState(() {
          _mealCategories = value;
          _selectMatchingFavoriteCategory();
        });
      }
    } on Object catch (error) {
      if (mounted) setState(() => _categoriesError = error.toString());
    } finally {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  Future<void> _chooseFavoriteFood() async {
    final repository =
        Get.isRegistered<FavoritesRepository>()
            ? Get.find<FavoritesRepository>()
            : FavoritesRepository(
              provider: FavoritesProvider(
                authService: Get.find<AuthService>(),
              ),
            );
    final food = await showModalBottomSheet<FavoriteFood>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (sheetContext) => SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(sheetContext).height * .62,
              child: FutureBuilder<List<FavoriteFood>>(
                future: repository.getFoods(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final foods = snapshot.data ?? const <FavoriteFood>[];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                        child: Text(
                          'Choose a favorite food'.tr,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        child:
                            snapshot.hasError
                                ? Center(
                                  child: Text(
                                    'Unable to load favorite foods.'.tr,
                                    style: TextStyle(
                                      color: context.appMutedText,
                                    ),
                                  ),
                                )
                                : foods.isEmpty
                                ? Center(
                                  child: Text(
                                    'No favorite foods yet'.tr,
                                    style: TextStyle(
                                      color: context.appMutedText,
                                    ),
                                  ),
                                )
                                : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    20,
                                  ),
                                  itemCount: foods.length,
                                  separatorBuilder:
                                      (_, _) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final item = foods[index];
                                    return ListTile(
                                      onTap:
                                          () => Navigator.pop(context, item),
                                      tileColor: context.appSubtleSurface,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color: context.appBorder,
                                        ),
                                      ),
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: SizedBox.square(
                                          dimension: 48,
                                          child:
                                              item.image.isEmpty
                                                  ? const Icon(
                                                    Icons.restaurant_rounded,
                                                    color: green,
                                                  )
                                                  : Image.network(
                                                    item.image,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, _, _) => const Icon(
                                                          Icons
                                                              .restaurant_rounded,
                                                          color: green,
                                                        ),
                                                  ),
                                        ),
                                      ),
                                      title: Text(
                                        item.name.tr,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: Text('${item.calories} kcal'),
                                      trailing: const Icon(
                                        Icons.add_circle_rounded,
                                        color: green,
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
    );
    if (food == null || !mounted) return;

    Uint8List? imageBytes;
    final imageUri = Uri.tryParse(food.image);
    if (imageUri != null && imageUri.hasScheme) {
      try {
        final response = await http.get(imageUri);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          imageBytes = response.bodyBytes;
        }
      } on Object {
        // The food details can still be used if its image cannot be copied.
      }
    }
    if (!mounted) return;
    _name.text = food.name;
    setState(() {
      _selectedFavoriteFood = food;
      if (imageBytes != null) _image = imageBytes;
      _selectMatchingFavoriteCategory();
    });
  }

  void _selectMatchingFavoriteCategory() {
    final favorite = _selectedFavoriteFood;
    if (favorite == null) return;
    for (final category in _mealCategories) {
      if (category.name.trim().toLowerCase() ==
          favorite.category.trim().toLowerCase()) {
        _selectedCategoryId = category.id;
        return;
      }
    }
  }

  @override
  void dispose() {
    _ingredientSearchDebounce?.cancel();
    _name.removeListener(_refreshBasicInfoState);
    _time.removeListener(_refreshBasicInfoState);
    _servings.removeListener(_refreshBasicInfoState);
    _name.dispose();
    _time.dispose();
    _servings.dispose();
    for (final item in _ingredients) {
      item.dispose();
    }
    _newIngredient.dispose();
    for (final item in _steps) {
      item.dispose();
    }
    _newStep.dispose();
    super.dispose();
  }

  void _refreshBasicInfoState() {
    if (mounted) setState(() {});
  }

  bool get _isBasicInfoComplete =>
      _name.text.trim().isNotEmpty &&
      (int.tryParse(_time.text.trim()) ?? 0) > 0 &&
      (int.tryParse(_servings.text.trim()) ?? 0) > 0 &&
      _selectedCategoryId != null;

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
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
              decoration: BoxDecoration(
                color: sheetContext.appSurfaceLow,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add a meal photo',
                    style: TextStyle(
                      color: sheetContext.appText,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Choose how you would like to add your cover photo.',
                    style: TextStyle(
                      color: sheetContext.appMutedText,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: sheetContext.appMutedSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: sheetContext.appBorder),
                    ),
                    child: Column(
                      children: [
                        _PhotoSourceTile(
                          icon: Icons.photo_library_outlined,
                          title: 'Choose from gallery',
                          subtitle: 'Select an existing photo',
                          onTap:
                              () => Navigator.pop(
                                sheetContext,
                                ImageSource.gallery,
                              ),
                        ),
                        Divider(
                          height: 1,
                          indent: 68,
                          color: sheetContext.appBorder,
                        ),
                        _PhotoSourceTile(
                          icon: Icons.photo_camera_outlined,
                          title: 'Take a photo',
                          subtitle: 'Use your camera now',
                          onTap:
                              () => Navigator.pop(
                                sheetContext,
                                ImageSource.camera,
                              ),
                        ),
                      ],
                    ),
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
      Get.snackbar(
        'Select a category',
        'Choose a meal category before publishing.',
      );
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
    if (ingredients.any((item) => item.amount == null || item.amount! <= 0)) {
      Get.snackbar(
        'Recipe incomplete',
        'Every ingredient needs a valid amount.',
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        CommunityPostDraft(
          mealName: _name.text.trim(),
          description: '',
          cookingTimeMinutes: int.parse(_time.text),
          servings: int.parse(_servings.text),
          difficulty: _difficulty,
          ingredients: ingredients,
          steps: List.generate(
            steps.length,
            (index) => MealPostStep(
              stepNumber: index + 1,
              instruction: steps[index].text.trim(),
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

  void _continueToRecipe() {
    setState(() => _showValidation = true);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      Get.snackbar(
        'Select a category',
        'Choose a meal category before continuing.',
      );
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

  void _addStep() {
    final instruction = _newStep.text.trim();
    if (instruction.isEmpty) {
      Get.snackbar('Add cooking instructions', 'Describe the step first.');
      return;
    }
    setState(() {
      _steps.add(TextEditingController(text: instruction));
      _newStep.clear();
    });
    FocusScope.of(context).unfocus();
  }

  void _moveStep(int index, int offset) {
    final target = index + offset;
    if (target < 0 || target >= _steps.length) return;
    setState(() {
      final step = _steps.removeAt(index);
      _steps.insert(target, step);
    });
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
    _ingredientSearchDebounce = Timer(
      const Duration(milliseconds: 250),
      () async {
        try {
          final results = await Get.find<CommunityRepository>()
              .searchIngredients(query);
          if (mounted && requestVersion == _ingredientSearchVersion) {
            setState(() => _ingredientSuggestions = results);
          }
        } on Object {
          // A temporary search failure should never prevent someone entering an
          // ingredient manually.
        }
      },
    );
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

  Future<void> _createAndSelectTag(String name, StateSetter updateSheet) async {
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
      showDragHandle: false,
      backgroundColor: Colors.transparent,
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
                top: false,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    22,
                    20,
                    MediaQuery.viewInsetsOf(context).bottom + 24,
                  ),
                  decoration: BoxDecoration(
                    color: context.appSurfaceLow,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * .72,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add meal tags',
                          style: TextStyle(
                            color: context.appText,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Choose a tag, create your own, or use the food name.',
                          style: TextStyle(
                            color: context.appMutedText,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: search,
                          autofocus: true,
                          onChanged: (_) => updateSheet(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search tags',
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor: context.appMutedSurface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: context.appBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: context.appBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: green,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Flexible(
                          child: ListView(
                            shrinkWrap: true,
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            children: [
                              ...visible.map(
                                (tag) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _TagSelectionTile(
                                    label: tag.name,
                                    selected: _selectedTags.contains(tag.id),
                                    onTap: () {
                                      final selected =
                                          !_selectedTags.contains(tag.id);
                                      setState(
                                        () =>
                                            selected
                                                ? _selectedTags.add(tag.id)
                                                : _selectedTags.remove(tag.id),
                                      );
                                      updateSheet(() {});
                                    },
                                  ),
                                ),
                              ),
                              if (visible.isEmpty &&
                                  (query.isEmpty || exactMatch))
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No tags available.',
                                      style: TextStyle(
                                        color: context.appMutedText,
                                      ),
                                    ),
                                  ),
                                ),
                              if (query.isEmpty &&
                                  mealName.isNotEmpty &&
                                  !hasMealNameTag)
                                _TagCreateTile(
                                  icon: Icons.restaurant_menu_rounded,
                                  title: 'Use food name: "$mealName"',
                                  loading: _creatingTag,
                                  onTap:
                                      _creatingTag
                                          ? null
                                          : () => _createAndSelectTag(
                                            mealName,
                                            updateSheet,
                                          ),
                                ),
                              if (query.isNotEmpty && !exactMatch)
                                _TagCreateTile(
                                  icon: Icons.add_rounded,
                                  title: 'Create "${search.text.trim()}"',
                                  loading: _creatingTag,
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
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: FilledButton.styleFrom(
                              backgroundColor: green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              _selectedTags.isEmpty
                                  ? 'Done'
                                  : 'Done (${_selectedTags.length})',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
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
  Widget build(BuildContext context) => PopScope<void>(
    canPop: _currentStep == 0 && !_submitting,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !_submitting) _handleBack();
    },
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            autovalidateMode:
                _showValidation
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
            child: ListView(
              key: ValueKey('community-post-editor-scroll-$_currentStep'),
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                _editorHeader(),
                const SizedBox(height: 12),
                _progressHeader(),
                const SizedBox(height: 18),
                if (_currentStep == 0)
                  ..._basicInfoFields()
                else
                  ..._recipeFields(),
                const SizedBox(height: 20),
                _navigationButton(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _navigationButton() => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 50),
    child: FilledButton(
      onPressed:
          _submitting || (_currentStep == 0 && !_isBasicInfoComplete)
              ? null
              : _currentStep == 0
              ? _continueToRecipe
              : _submit,
      style: FilledButton.styleFrom(
        backgroundColor: green,
        foregroundColor: Colors.white,
        disabledBackgroundColor: context.appMutedSurface,
        disabledForegroundColor: context.appMutedText,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                        ? 'Continue to ingredients'
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
  );

  Widget _editorHeader() => SizedBox(
    height: AppBackButton.layoutSize,
    child: Row(
      children: [
        AppBackButton(onPressed: _submitting ? null : _handleBack),
        Expanded(
          child: Center(
            child: Text(
              widget.post == null ? 'New meal' : 'Edit meal',
              style: TextStyle(
                color: context.appText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppBackButton.layoutSize),
      ],
    ),
  );

  void _handleBack() {
    if (_currentStep == 1) {
      setState(() {
        _currentStep = 0;
        _showValidation = false;
      });
      return;
    }
    Navigator.maybePop(context);
  }

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
                  ? context.appColorScheme.primary
                  : context.appBorder,
        ),
      ),
      _progressStep(2, 'Ingredients', isActive: _currentStep == 1),
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
                  ? context.appSelectedSurface
                  : context.appMutedSurface,
        ),
        child:
            isComplete
                ? const Icon(Icons.check_rounded, size: 14, color: green)
                : Text(
                  '$number',
                  style: TextStyle(
                    color: isActive ? Colors.white : context.appMutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
      ),
      const SizedBox(width: 7),
      Text(
        label,
        style: TextStyle(
          color:
              isActive ? context.appColorScheme.primary : context.appMutedText,
          fontSize: 11,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ],
  );

  List<Widget> _basicInfoFields() => [
    Material(
      color: context.appSoftGreen,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: _submitting ? null : _chooseFavoriteFood,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.bookmark_rounded, color: green, size: 22),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFavoriteFood?.name ?? 'Choose from favorites',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedFavoriteFood == null
                          ? 'Prefill this post with one of your saved foods'
                          : 'Food details added — tap to choose another',
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: green),
            ],
          ),
        ),
      ),
    ),
    const SizedBox(height: 14),
    InkWell(
      onTap: _submitting ? null : _chooseImage,
      borderRadius: BorderRadius.circular(30),
      child: CustomPaint(
        foregroundPainter: _DashedRoundedBorder(
          color:
              context.appIsDark
                  ? context.appColorScheme.primary.withValues(alpha: .48)
                  : const Color(0xFFB7DEC7),
          radius: 30,
        ),
        child: Container(
          height: 206,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.appSubtleSurface,
            borderRadius: BorderRadius.circular(30),
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
                      color: Colors.black.withValues(alpha: .55),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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
    ),
    const SizedBox(height: 26),
    _field(
      _name,
      'Meal name',
      hint: 'Khmer Fish Amok',
      icon: Icons.restaurant_menu_rounded,
      validator:
          (v) =>
              v == null || v.trim().isEmpty ? 'Meal name is required.' : null,
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
    Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.appSoftGreen,
            shape: BoxShape.circle,
          ),
          child: const SizedBox(
            width: 22,
            height: 22,
            child: Icon(Icons.tune_rounded, color: green, size: 13),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          'Difficulty',
          style: TextStyle(
            color: context.appText,
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
        color: context.appMutedSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorder),
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

  Widget _emptyPhotoPrompt() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: context.appElevatedSurface,
            shape: BoxShape.circle,
            boxShadow: context.appTileShadow,
          ),
          child: const Icon(Icons.add_a_photo_outlined, color: green, size: 26),
        ),
        const SizedBox(height: 12),
        Text(
          'Add a cover photo',
          style: TextStyle(color: context.appText, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'A clear photo helps your meal stand out',
          style: TextStyle(color: context.appMutedText, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, color: context.appMutedText, size: 14),
            const SizedBox(width: 5),
            Text(
              'Recommended',
              style: TextStyle(color: context.appMutedText, fontSize: 11),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _mealCategoryField() {
    if (_categoriesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (_categoriesError != null) {
      return _inlineError(
        'Meal categories could not be loaded.',
        _loadMealCategories,
      );
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
          const Text(
            'Meal category',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color:
                    selectedCategory == null
                        ? context.appSubtleSurface
                        : context.appSelectedSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selectedCategory == null ? context.appBorder : green,
                ),
              ),
              child: InkWell(
                onTap: _submitting ? null : _showMealCategoryPicker,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                              selectedCategory == null
                                  ? context.appElevatedSurface
                                  : green,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _mealCategoryIcon(selectedCategory?.name ?? ''),
                          color:
                              selectedCategory == null ? green : Colors.white,
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
                                color:
                                    selectedCategory == null
                                        ? context.appText
                                        : context.appColorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedCategory == null
                                  ? 'Select where your meal belongs'
                                  : 'Tap to change',
                              style: TextStyle(
                                color: context.appMutedText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: context.appMutedText,
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
      builder:
          (sheetContext) => SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
              decoration: BoxDecoration(
                color: sheetContext.appElevatedSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
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
                          color: sheetContext.appStrongBorder,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Choose meal category',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This is where your meal will appear after approval.',
                      style: TextStyle(
                        color: sheetContext.appMutedText,
                        fontSize: 13,
                      ),
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
                            color:
                                selected
                                    ? sheetContext.appSelectedSurface
                                    : sheetContext.appSubtleSurface,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap:
                                  () =>
                                      Navigator.pop(sheetContext, category.id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color:
                                            selected
                                                ? green
                                                : sheetContext
                                                    .appElevatedSurface,
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
                                          color: sheetContext.appText,
                                          fontSize: 15,
                                          fontWeight:
                                              selected
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (selected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: green,
                                      ),
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
    if (name.contains('breakfast') || name.contains('brunch')) {
      return Icons.egg_alt_rounded;
    }
    if (name.contains('snack') || name.contains('dessert')) {
      return Icons.bakery_dining_rounded;
    }
    if (name.contains('beverage') || name.contains('drink')) {
      return Icons.local_drink_rounded;
    }
    if (name.contains('appetizer')) return Icons.tapas_rounded;
    if (name.contains('late')) return Icons.nightlight_round;
    if (name.contains('lunch') || name.contains('dinner')) {
      return Icons.dinner_dining_rounded;
    }
    return Icons.restaurant_rounded;
  }

  List<Widget> _recipeFields() => [
    _heading(
      'Ingredients',
      'Optional — add them if you want to share the full recipe.',
      Icons.shopping_basket_outlined,
    ),
    _ingredientComposer(),
    const SizedBox(height: 12),
    _ingredientList(),
    _heading(
      'How to cook',
      'Optional — add steps only when they help explain your meal.',
      Icons.restaurant_menu_rounded,
    ),
    _stepComposer(),
    const SizedBox(height: 12),
    _stepList(),
    _heading('Tags', 'Help people discover your meal.', Icons.sell_outlined),
    _tagsField(),
    _heading(
      'Who can see it',
      'Choose the audience for this post.',
      Icons.visibility_outlined,
    ),
    _audienceField(),
  ];

  Widget _tagsField() {
    if (_tagsLoading) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_tagsError != null) {
      return _inlineError('Tags could not be loaded.', _loadTags);
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._tags.where((tag) => _selectedTags.contains(tag.id)).map((tag) {
          return FilterChip(
            label: Text(tag.name),
            selected: true,
            showCheckmark: false,
            backgroundColor: context.appElevatedSurface,
            selectedColor: context.appSelectedSurface,
            labelStyle: TextStyle(
              color: context.appColorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            side: BorderSide(
              color: context.appColorScheme.primary.withValues(alpha: .5),
            ),
            shape: const StadiumBorder(),
            onSelected:
                _submitting
                    ? null
                    : (_) => setState(() => _selectedTags.remove(tag.id)),
          );
        }),
        ActionChip(
          key: const ValueKey('community-add-tag'),
          avatar: const Icon(Icons.add_rounded, size: 17, color: green),
          label: const Text('Add tag'),
          backgroundColor: context.appElevatedSurface,
          side: BorderSide(
            color: context.appColorScheme.primary.withValues(alpha: .5),
          ),
          shape: const StadiumBorder(),
          labelStyle: TextStyle(
            color: context.appColorScheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          onPressed: _submitting ? null : _showTagPicker,
        ),
      ],
    );
  }

  Widget _audienceField() => Container(
    key: const ValueKey<String>('community-post-audience'),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: context.appElevatedSurface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.appBorder),
      boxShadow: context.appTileShadow,
    ),
    child: Column(
      children: [
        _audienceOption(CommunityPostVisibility.public),
        Divider(height: 1, color: context.appBorder),
        _audienceOption(CommunityPostVisibility.followers),
      ],
    ),
  );

  Widget _audienceOption(CommunityPostVisibility value) {
    final selected = _visibility == value;
    return Material(
      color: selected ? context.appSelectedSurface : Colors.transparent,
      child: InkWell(
        onTap: _submitting ? null : () => setState(() => _visibility = value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected ? green : context.appSoftGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  value.icon,
                  size: 19,
                  color: selected ? Colors.white : green,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      value.description,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? green : context.appBorder,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                decoration: BoxDecoration(
                  color: context.appSoftGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: green, size: 13),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                color: context.appText,
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
  InputDecoration _decoration({
    String? hint,
    String? suffix,
  }) => InputDecoration(
    hintText: hint,
    suffixText: suffix,
    filled: true,
    fillColor: context.appField,
    hintStyle: TextStyle(color: context.appMutedText),
    suffixStyle: TextStyle(
      color: context.appMutedText,
      fontWeight: FontWeight.w600,
    ),
    counterStyle: TextStyle(color: context.appMutedText, fontSize: 11),
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: context.appBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: context.appBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: context.appColorScheme.primary, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFFCF3B3B)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFFCF3B3B), width: 1.5),
    ),
  );

  Widget _inlineError(String message, VoidCallback retry) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.appWarningSurface,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(Icons.cloud_off_outlined, color: context.appOnWarningSurface),
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
              decoration: BoxDecoration(
                color: context.appSoftGreen,
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
        Text(subtitle, style: TextStyle(color: context.appMutedText)),
      ],
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
            borderRadius: BorderRadius.circular(19),
            boxShadow:
                selected
                    ? const [
                      BoxShadow(
                        color: Color(0x123C9C70),
                        blurRadius: 6,
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
                size: 18,
                color: selected ? Colors.white : context.appMutedText,
              ),
              const SizedBox(width: 5),
              Text(
                value[0] + value.substring(1).toLowerCase(),
                style: TextStyle(
                  color: selected ? Colors.white : context.appText,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ingredientComposer() {
    final amount = num.tryParse(_newIngredient.amount.text.trim());
    final isReady =
        _newIngredient.name.text.trim().isNotEmpty &&
        amount != null &&
        amount > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appTileShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _newIngredient.name,
            onChanged: _searchIngredients,
            decoration: _decoration(
              hint: 'Search ingredient',
            ).copyWith(prefixIcon: const Icon(Icons.search_rounded, size: 20)),
            textInputAction: TextInputAction.next,
          ),
          if (_ingredientSuggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ingredientSuggestionPanel(),
          ],
          const SizedBox(height: 12),
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
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) {
                    if (isReady) _addIngredient();
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 92,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _submitting ? null : _showIngredientUnitPicker,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: _decoration(),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _newIngredient.unit,
                              style: TextStyle(
                                color: context.appText,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: context.appMutedText,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const ValueKey('community-add-ingredient'),
                tooltip: 'Add ingredient to list',
                onPressed: _submitting || !isReady ? null : _addIngredient,
                icon: const Icon(Icons.add_rounded, size: 23),
                style: IconButton.styleFrom(
                  backgroundColor: green,
                  disabledBackgroundColor: context.appMutedSurface,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: context.appMutedText,
                  fixedSize: const Size.square(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showIngredientUnitPicker() async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
              decoration: BoxDecoration(
                color: sheetContext.appSurfaceLow,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose measurement unit',
                    style: TextStyle(
                      color: sheetContext.appText,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Select the unit used for this ingredient amount.',
                    style: TextStyle(
                      color: sheetContext.appMutedText,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 2.25,
                        ),
                    itemCount: _ingredientUnits.length,
                    itemBuilder: (context, index) {
                      final unit = _ingredientUnits[index];
                      final isSelected = unit == _newIngredient.unit;
                      return Material(
                        color:
                            isSelected
                                ? sheetContext.appSelectedSurface
                                : sheetContext.appMutedSurface,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => Navigator.pop(sheetContext, unit),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    isSelected ? green : sheetContext.appBorder,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isSelected) ...[
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: green,
                                    size: 17,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  unit,
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? green
                                            : sheetContext.appText,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
    );
    if (selected != null && mounted) {
      setState(() => _newIngredient.unit = selected);
    }
  }

  Widget _ingredientSuggestionPanel() => Container(
    constraints: const BoxConstraints(maxHeight: 180),
    decoration: BoxDecoration(
      color: context.appElevatedSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: context.appColorScheme.primary.withValues(alpha: .4),
      ),
      boxShadow: context.appTileShadow,
    ),
    child: ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _ingredientSuggestions.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final ingredient = _ingredientSuggestions[index];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.restaurant_rounded, color: green, size: 20),
          title: Text(ingredient.name),
          trailing:
              ingredient.defaultUnit.isEmpty
                  ? null
                  : Text(
                    ingredient.defaultUnit,
                    style: TextStyle(color: context.appMutedText),
                  ),
          onTap: () => _selectIngredient(ingredient),
        );
      },
    ),
  );

  Widget _ingredientList() {
    if (_ingredients.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Icon(
              Icons.checklist_rounded,
              color: context.appMutedText,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Nothing added yet — search above to start your list.',
                style: TextStyle(color: context.appMutedText, fontSize: 11),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Row(
            children: [
              const Text(
                'Ingredients list',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: context.appSoftGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_ingredients.length}',
                  style: TextStyle(
                    color: context.appColorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.appElevatedSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appBorder),
          ),
          child: Column(
            children: List.generate(_ingredients.length, (index) {
              final item = _ingredients[index];
              return Column(
                children: [
                  _ingredientListRow(index, item),
                  if (index < _ingredients.length - 1)
                    Divider(height: 1, color: context.appBorder),
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
        Icon(
          Icons.drag_indicator_rounded,
          size: 17,
          color: context.appMutedText,
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
            style: TextStyle(fontSize: 11, color: context.appMutedText),
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
          color: context.appMutedText,
        ),
        const SizedBox(width: 2),
      ],
    ),
  );

  Widget _stepComposer() {
    final isReady = _newStep.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appTileShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: context.appSoftGreen,
                child: Text(
                  '${_steps.length + 1}',
                  style: const TextStyle(
                    color: green,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                'Step ${_steps.length + 1}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: const ValueKey('community-new-cooking-step'),
            controller: _newStep,
            minLines: 2,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (isReady) _addStep();
            },
            decoration: _decoration(hint: 'Describe this cooking step'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('community-add-cooking-step'),
              onPressed: _submitting || !isReady ? null : _addStep,
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Add step to list'),
              style: FilledButton.styleFrom(
                backgroundColor: green,
                disabledBackgroundColor: context.appMutedSurface,
                disabledForegroundColor: context.appMutedText,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(44),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepList() {
    if (_steps.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Icon(
              Icons.checklist_rounded,
              color: context.appMutedText,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No steps yet — write one above and add it to your recipe.',
                style: TextStyle(color: context.appMutedText, fontSize: 11),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Row(
            children: [
              const Text(
                'Cooking steps',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: context.appSoftGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_steps.length}',
                  style: TextStyle(
                    color: context.appColorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.appElevatedSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.appBorder),
          ),
          child: Column(
            children: List.generate(_steps.length, (index) {
              return Column(
                children: [
                  _stepListRow(index),
                  if (index < _steps.length - 1)
                    Divider(height: 1, color: context.appBorder),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _stepListRow(int index) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 7, 4, 7),
    child: Row(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: context.appSoftGreen,
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: green,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _steps[index].text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        IconButton(
          key: ValueKey('community-step-up-$index'),
          tooltip: 'Move step ${index + 1} up',
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          padding: EdgeInsets.zero,
          onPressed: index == 0 ? null : () => _moveStep(index, -1),
          icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
          color: green,
          disabledColor: context.appMutedText.withValues(alpha: .4),
        ),
        IconButton(
          key: ValueKey('community-step-down-$index'),
          tooltip: 'Move step ${index + 1} down',
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          padding: EdgeInsets.zero,
          onPressed:
              index == _steps.length - 1 ? null : () => _moveStep(index, 1),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          color: green,
          disabledColor: context.appMutedText.withValues(alpha: .4),
        ),
        IconButton(
          tooltip: 'Remove step ${index + 1}',
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 38, height: 34),
          padding: EdgeInsets.zero,
          onPressed: () {
            _steps[index].dispose();
            setState(() => _steps.removeAt(index));
          },
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          color: context.appMutedText,
        ),
      ],
    ),
  );
}

class _PhotoSourceTile extends StatelessWidget {
  const _PhotoSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.appSoftGreen,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: _CommunityPostEditorPageState.green, size: 21),
    ),
    title: Text(
      title,
      style: TextStyle(
        color: context.appText,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: TextStyle(color: context.appMutedText, fontSize: 12),
    ),
    trailing: Icon(
      Icons.chevron_right_rounded,
      color: context.appMutedText,
      size: 22,
    ),
  );
}

class _TagSelectionTile extends StatelessWidget {
  const _TagSelectionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? context.appSelectedSurface : context.appMutedSurface,
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color:
                selected
                    ? _CommunityPostEditorPageState.green
                    : context.appBorder,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color:
                    selected
                        ? _CommunityPostEditorPageState.green
                        : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      selected
                          ? _CommunityPostEditorPageState.green
                          : context.appStrongBorder,
                ),
              ),
              child:
                  selected
                      ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 17,
                      )
                      : null,
            ),
          ],
        ),
      ),
    ),
  );
}

class _TagCreateTile extends StatelessWidget {
  const _TagCreateTile({
    required this.icon,
    required this.title,
    required this.loading,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: context.appMutedSurface,
      borderRadius: BorderRadius.circular(15),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: context.appBorder),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        leading: CircleAvatar(
          backgroundColor: context.appSoftGreen,
          child: Icon(
            icon,
            color: _CommunityPostEditorPageState.green,
            size: 20,
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.appText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: const Text('Create and select tag'),
        trailing:
            loading
                ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Icon(Icons.add_circle_outline_rounded),
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

class _DashedRoundedBorder extends CustomPainter {
  const _DashedRoundedBorder({required this.color, required this.radius})
    : dashLength = 4,
      gapLength = 4;

  final Color color;
  final double radius;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final path =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Offset(.5, .5) & Size(size.width - 1, size.height - 1),
            Radius.circular(radius),
          ),
        );
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next =
            (distance + dashLength).clamp(0.0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorder oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.gapLength != gapLength;
}
