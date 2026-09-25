import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/auth_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../translations/localized_text.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
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
    this.initialPickImage = false,
    super.key,
  });
  final CommunityPost? post;
  final String authorName;
  final String authorAvatarUrl;
  final Future<void> Function(CommunityPostDraft draft) onSubmit;
  final bool initialPickImage;
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
  late final TextEditingController _description, _time, _servings;
  late List<_IngredientInput> _ingredients;
  final _newIngredient = _IngredientInput();
  List<IngredientSuggestion> _ingredientSuggestions = const [];
  Timer? _ingredientSearchDebounce;
  int _ingredientSearchVersion = 0;
  late List<TextEditingController> _steps;
  String _difficulty = 'EASY';
  static const _maxImages = 5;
  final List<Uint8List> _images = [];
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
  late final TextEditingController _ingredientSearchController;
  late final TextEditingController _ingredientAmountController;
  late final TextEditingController _currentStepInputController;
  String _selectedUnit = 'g';
  bool _showIngredientSuggestions = false;
  final FocusNode _ingredientNameFocusNode = FocusNode();
  final FocusNode _ingredientAmountFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final post = widget.post;
    // Older recipe posts did not collect a caption.  Start their editor with
    // the existing title so users can turn it into a proper description.
    _description = TextEditingController(
      text: post?.description.isNotEmpty == true
          ? post!.description
          : post?.mealName ?? '',
    );
    _time = TextEditingController(
      text: post?.cookingTimeMinutes?.toString() ?? '',
    );
    _servings = TextEditingController(text: post?.servings?.toString() ?? '');
    _ingredientSearchController = TextEditingController();
    _ingredientAmountController = TextEditingController();
    _currentStepInputController = TextEditingController();
    _description.addListener(_refreshBasicInfoState);
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
    if (widget.initialPickImage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _chooseImage();
      });
    }
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
      if (mounted) {
        setState(() {
          final loadedIds = value.map((item) => item.id).toSet();
          final locallyAdded = _tags.where(
            (item) => !loadedIds.contains(item.id),
          );
          _tags = [...value, ...locallyAdded]
            ..sort((a, b) => a.name.compareTo(b.name));
        });
      }
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
              provider: FavoritesProvider(authService: Get.find<AuthService>()),
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
                          'community.choose_favorite_food'.tr,
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
                                    'community.favorite_foods_load_failed'.tr,
                                    style: TextStyle(
                                      color: context.appMutedText,
                                    ),
                                  ),
                                )
                                : foods.isEmpty
                                ? Center(
                                  child: Text(
                                    'common.no_favorite_foods_yet'.tr,
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
                                      onTap: () => Navigator.pop(context, item),
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
                                        item.name,
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
    _description.text = food.name;
    setState(() {
      _selectedFavoriteFood = food;
      if (imageBytes != null) _images.add(imageBytes);
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
    _description.removeListener(_refreshBasicInfoState);
    _time.removeListener(_refreshBasicInfoState);
    _servings.removeListener(_refreshBasicInfoState);
    _description.dispose();
    _time.dispose();
    _servings.dispose();
    _ingredientSearchController.dispose();
    _ingredientAmountController.dispose();
    _currentStepInputController.dispose();
    _ingredientNameFocusNode.dispose();
    _ingredientAmountFocusNode.dispose();
    for (final item in _ingredients) {
      item.dispose();
    }
    _newIngredient.dispose();
    for (final item in _steps) {
      item.dispose();
    }
    super.dispose();
  }

  void _refreshBasicInfoState() {
    if (mounted) setState(() {});
  }

  Future<void> _pickImage(ImageSource source) async {
    final existingCount = widget.post?.imageUrls.length ?? 0;
    final remaining = _maxImages - existingCount - _images.length;
    if (remaining <= 0) return;
    final files =
        source == ImageSource.gallery
            ? await _picker.pickMultiImage(imageQuality: 85, maxWidth: 1800)
            : <XFile>[
              if (await _picker.pickImage(
                    source: source,
                    imageQuality: 85,
                    maxWidth: 1800,
                  )
                  case final file?)
                file,
            ];
    if (files.isEmpty) return;
    final selected = <Uint8List>[];
    for (final file in files.take(remaining)) {
      selected.add(await file.readAsBytes());
    }
    if (mounted) setState(() => _images.addAll(selected));
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
                    'common.add_a_meal_photo'.tr,
                    style: TextStyle(
                      color: sheetContext.appText,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'community.photo_source_prompt'.tr,
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
                          title: 'community.choose_gallery'.tr,
                          subtitle: 'community.choose_gallery_help'.tr,
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
                          title: 'community.take_photo'.tr,
                          subtitle: 'community.take_photo_help'.tr,
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
          : 'community.positive_value'.trParams({'label': label.trOrSelf});

  Future<void> _submit() async {
    final searchName = _ingredientSearchController.text.trim();
    final newName = _newIngredient.name.text.trim();
    final name = searchName.isNotEmpty ? searchName : newName;
    final amountText =
        _ingredientAmountController.text.trim().isNotEmpty
            ? _ingredientAmountController.text.trim()
            : _newIngredient.amount.text.trim();
    final amount = num.tryParse(amountText);
    if (name.isNotEmpty && amount != null && amount > 0) {
      _ingredients.add(
        _IngredientInput(
          name: name,
          amount: amountText,
          unit: _selectedUnit,
        ),
      );
      _ingredientSearchController.clear();
      _ingredientAmountController.clear();
      _newIngredient.name.clear();
      _newIngredient.amount.clear();
    }
    final stepText = _currentStepInputController.text.trim();
    if (stepText.isNotEmpty) {
      _steps.add(TextEditingController(text: stepText));
      _currentStepInputController.clear();
    }

    setState(() => _showValidation = true);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      await AppAlert.actionError(
        title: 'community.select_category',
        message: 'community.category_before_publish',
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
      await AppAlert.actionError(
        title: 'community.recipe_incomplete',
        message: 'community.ingredient_amounts_invalid',
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        CommunityPostDraft(
          // Recipes still require a short name in the API.  Use a compact
          // first line as an internal title while displaying the full text as
          // the community description.
          mealName: _titleFromDescription(_description.text),
          description: _description.text.trim(),
          cookingTimeMinutes: int.tryParse(_time.text.trim()) ?? 0,
          servings: int.tryParse(_servings.text.trim()) ?? 1,
          difficulty: _difficulty,
          ingredients: ingredients,
          steps: List.generate(
            steps.length,
            (index) => MealPostStep(
              stepNumber: index + 1,
              instruction: steps[index].text.trim(),
            ),
          ),
          imageBytes: List.unmodifiable(_images),
          removeImage: false,
          visibility: _visibility,
          allowComments: true,
          allowReplies: true,
          tagIds: _selectedTags.toList(),
          categoryId: _selectedCategoryId,
        ),
      );
      if (mounted) {
        final isEditing = widget.post != null;
        Get.back(result: true);
        await AppAlert.actionSuccess(
          title:
              isEditing ? 'community.meal_updated' : 'community.meal_published',
          message:
              isEditing
                  ? 'community.changes_saved'
                  : 'community.new_meal_available',
        );
      }
    } on Object catch (error) {
      await AppAlert.actionError(
        title: 'community.could_not_publish_meal',
        message: error.toString(),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _continueToRecipe() {
    setState(() => _showValidation = true);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      Get.snackbar(
        'community.select_category'.tr,
        'community.category_before_continue'.tr,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _showValidation = false;
      _currentStep = 1;
    });
  }

  void _searchIngredients(String rawQuery) {
    _ingredientSearchDebounce?.cancel();
    final query = rawQuery.trim();
    final requestVersion = ++_ingredientSearchVersion;
    if (query.isEmpty) {
      setState(() {
        _ingredientSuggestions = const [];
        _showIngredientSuggestions = false;
      });
      return;
    }
    setState(() => _showIngredientSuggestions = true);
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
      _ingredientSearchController.text = ingredient.name;
      _newIngredient.name.text = ingredient.name;
      if (ingredient.defaultUnit.isNotEmpty) {
        _selectedUnit = ingredient.defaultUnit;
        _newIngredient.unit = ingredient.defaultUnit;
      }
      _ingredientSuggestions = const [];
      _showIngredientSuggestions = false;
    });
    FocusScope.of(context).unfocus();
    _ingredientAmountFocusNode.requestFocus();
  }

  void _selectCustomIngredient(String name) {
    setState(() {
      _ingredientSearchController.text = name;
      _newIngredient.name.text = name;
      _ingredientSuggestions = const [];
      _showIngredientSuggestions = false;
    });
    FocusScope.of(context).unfocus();
    _ingredientAmountFocusNode.requestFocus();
  }

  Future<void> _editIngredient(int index) async {
    final item = _ingredients[index];
    final nameController = TextEditingController(text: item.name.text);
    final amountController = TextEditingController(text: item.amount.text);
    var selectedUnit = item.unit;
    final formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => StatefulBuilder(
            builder:
                (context, setSheetState) => SafeArea(
                  top: false,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
                    ),
                    decoration: BoxDecoration(
                      color: sheetContext.appSurfaceLow,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              height: 4,
                              width: 38,
                              decoration: BoxDecoration(
                                color: sheetContext.appStrongBorder,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'community.edit_ingredient'.tr,
                            style: TextStyle(
                              color: sheetContext.appText,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: nameController,
                            autofocus: true,
                            decoration: _decoration(
                              hint: 'community.ingredient_name_placeholder'.tr,
                            ),
                            validator:
                                (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'community.ingredient_details_help'.tr
                                        : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: amountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: _decoration(
                                    hint: 'community.amount_placeholder'.tr,
                                  ),
                                  validator: (v) {
                                    final n = num.tryParse(v?.trim() ?? '');
                                    if (n == null || n <= 0) {
                                      return 'community.ingredient_details_help'
                                          .tr;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: InkWell(
                                  onTap: () async {
                                    final chosen =
                                        await _showIngredientUnitPicker(
                                          selectedUnit,
                                        );
                                    if (chosen != null &&
                                        sheetContext.mounted) {
                                      setSheetState(
                                        () => selectedUnit = chosen,
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(15),
                                  child: InputDecorator(
                                    decoration: _decoration(),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            selectedUnit,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: sheetContext.appText,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: sheetContext.appMutedText,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed:
                                    () => Navigator.pop(sheetContext, false),
                                style: TextButton.styleFrom(
                                  foregroundColor: sheetContext.appMutedText,
                                ),
                                child: Text('common.cancel'.tr),
                              ),
                              const SizedBox(width: 10),
                              FilledButton(
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    Navigator.pop(sheetContext, true);
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 11,
                                  ),
                                ),
                                child: Text(
                                  'common.save'.tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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

    if (saved == true && mounted) {
      setState(() {
        item.name.text = nameController.text.trim();
        item.amount.text = amountController.text.trim();
        item.unit = selectedUnit;
      });
    }
  }

  Future<void> _showAddCustomIngredientSheet() async {
    final nameController = TextEditingController(
      text: _ingredientSearchController.text.trim(),
    );
    final amountController = TextEditingController(
      text: _ingredientAmountController.text.trim(),
    );
    var selectedUnit = _selectedUnit;
    final formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => StatefulBuilder(
            builder:
                (context, setSheetState) => SafeArea(
                  top: false,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
                    ),
                    decoration: BoxDecoration(
                      color: sheetContext.appSurfaceLow,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              height: 4,
                              width: 38,
                              decoration: BoxDecoration(
                                color: sheetContext.appStrongBorder,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'community.add_custom_ingredient'.tr,
                            style: TextStyle(
                              color: sheetContext.appText,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: nameController,
                            autofocus: true,
                            decoration: _decoration(
                              hint: 'community.ingredient_name_placeholder'.tr,
                            ),
                            validator:
                                (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'community.ingredient_details_help'.tr
                                        : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: amountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: _decoration(
                                    hint: 'community.amount_placeholder'.tr,
                                  ),
                                  validator: (v) {
                                    final n = num.tryParse(v?.trim() ?? '');
                                    if (n == null || n <= 0) {
                                      return 'community.ingredient_details_help'
                                          .tr;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: InkWell(
                                  onTap: () async {
                                    final chosen =
                                        await _showIngredientUnitPicker(
                                          selectedUnit,
                                        );
                                    if (chosen != null &&
                                        sheetContext.mounted) {
                                      setSheetState(
                                        () => selectedUnit = chosen,
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(15),
                                  child: InputDecorator(
                                    decoration: _decoration(),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            selectedUnit,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: sheetContext.appText,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: sheetContext.appMutedText,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed:
                                    () => Navigator.pop(sheetContext, false),
                                style: TextButton.styleFrom(
                                  foregroundColor: sheetContext.appMutedText,
                                ),
                                child: Text('common.cancel'.tr),
                              ),
                              const SizedBox(width: 10),
                              FilledButton(
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    Navigator.pop(sheetContext, true);
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 11,
                                  ),
                                ),
                                child: Text(
                                  'common.add'.tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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

    if (saved == true && mounted) {
      final name = nameController.text.trim();
      final amount = amountController.text.trim();
      if (name.isNotEmpty && num.tryParse(amount) != null) {
        setState(() {
          _ingredients.add(
            _IngredientInput(name: name, amount: amount, unit: selectedUnit),
          );
          _ingredientSearchController.clear();
          _ingredientAmountController.clear();
          _newIngredient.name.clear();
          _newIngredient.amount.clear();
          _ingredientSuggestions = const [];
          _showIngredientSuggestions = false;
        });
      }
    }
  }

  Future<void> _showAddOrEditStepSheet({int? index}) async {
    final isEditing = index != null;
    final controller = TextEditingController(
      text: isEditing ? _steps[index].text : '',
    );
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => SafeArea(
            top: false,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
              ),
              decoration: BoxDecoration(
                color: sheetContext.appSurfaceLow,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        height: 4,
                        width: 38,
                        decoration: BoxDecoration(
                          color: sheetContext.appStrongBorder,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: sheetContext.appSoftGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${isEditing ? index + 1 : _steps.length + 1}',
                            style: const TextStyle(
                              color: green,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isEditing
                                ? 'community.edit_step'.tr
                                : 'community.step_number'.trParams({
                                  'number': '${_steps.length + 1}',
                                }),
                            style: TextStyle(
                              color: sheetContext.appText,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('community-new-cooking-step-input'),
                      controller: controller,
                      autofocus: true,
                      minLines: 3,
                      maxLines: 5,
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'community.describe_step_first'.tr
                                  : null,
                      decoration: _decoration(
                        hint: 'community.how_to_cook_subtitle'.tr,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          style: TextButton.styleFrom(
                            foregroundColor: sheetContext.appMutedText,
                          ),
                          child: Text('common.cancel'.tr),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          key: const ValueKey('community-save-step-button'),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(
                                sheetContext,
                                controller.text.trim(),
                              );
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 11,
                            ),
                          ),
                          child: Text(
                            isEditing
                                ? 'common.save'.tr
                                : 'community.add_step'.tr,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    if (result != null && mounted) {
      setState(() {
        if (isEditing) {
          _steps[index].text = result;
        } else {
          _steps.add(TextEditingController(text: result));
        }
      });
    }
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
      if (mounted) {
        Get.snackbar('community.could_not_create_tag'.tr, error.toString());
      }
    } finally {
      _creatingTag = false;
      updateSheet(() {});
    }
  }

  Future<void> _showTagPicker() async {
    var search = '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => StatefulBuilder(
            builder: (context, setSheetState) {
              // A tag request may finish after this sheet has been dismissed.
              void updateSheet(VoidCallback update) {
                if (context.mounted) setSheetState(update);
              }

              final query = search.trim().toLowerCase();
              final visible = _tags
                  .where((tag) => tag.name.toLowerCase().contains(query))
                  .toList(growable: false);
              final exactMatch = _tags.any(
                (tag) => tag.name.toLowerCase() == query,
              );
              final mealName = _titleFromDescription(_description.text);
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
                          'community.add_meal_tags'.tr,
                          style: TextStyle(
                            color: context.appText,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'community.tag_help'.tr,
                          style: TextStyle(
                            color: context.appMutedText,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          autofocus: true,
                          onChanged:
                              (value) => updateSheet(() => search = value),
                          decoration: InputDecoration(
                            hintText: 'community.search_tags'.tr,
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
                                      'community.no_tags'.tr,
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
                                  title: 'Create "${search.trim()}"',
                                  loading: _creatingTag,
                                  onTap:
                                      _creatingTag
                                          ? null
                                          : () => _createAndSelectTag(
                                            search,
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
                                  ? 'community.done'.tr
                                  : 'community.done_count'.trParams({
                                    'count': '${_selectedTags.length}',
                                  }),
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
  }

  double _contentMaxWidth(BuildContext context) {
    final isTablet = AppSpacing.isTabletFor(context);
    if (isTablet) return AppSpacing.maxWideContentWidth;
    return AppSpacing.maxContentWidth;
  }

  @override
  Widget build(BuildContext context) {
    final hPad = AppSpacing.pageHorizontalFor(context);
    final maxWidth = _contentMaxWidth(context);

    return PopScope<void>(
      canPop: _currentStep == 0 && !_submitting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_submitting) _handleBack();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: context.appBackground,
        body: Stack(
          children: [
            Positioned.fill(
              child: AppBackground(
                child: const SizedBox.expand(),
              ),
            ),
            // Ambient soft mint glow on top right
            Positioned(
              right: -40,
              top: 10,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0AAA55).withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
            // Ambient soft rose/peach glow on middle left
            Positioned(
              left: -50,
              top: 300,
              child: IgnorePointer(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF43F5E).withValues(alpha: 0.06),
                  ),
                ),
              ),
            ),
            // Ambient soft mint glow on bottom right
            Positioned(
              right: -50,
              bottom: 80,
              child: IgnorePointer(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0AAA55).withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      hPad,
                      AppSpacing.pageTop,
                      hPad,
                      0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: _editorHeader(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Form(
                          key: _formKey,
                          autovalidateMode:
                              _showValidation
                                  ? AutovalidateMode.onUserInteraction
                                  : AutovalidateMode.disabled,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isLandscape =
                                  MediaQuery.orientationOf(context) ==
                                  Orientation.landscape;
                              final isWide =
                                  isLandscape &&
                                  constraints.maxWidth >=
                                      AppSpacing.twoColumnBreakpoint;
                              return ListView(
                                key: ValueKey(
                                  'community-post-editor-scroll-$_currentStep',
                                ),
                                physics: const BouncingScrollPhysics(),
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: EdgeInsets.fromLTRB(
                                  hPad,
                                  4,
                                  hPad,
                                  28,
                                ),
                                children: [
                                  _progressHeader(),
                                  const SizedBox(height: 16),
                                  if (_currentStep == 0)
                                    _buildStep1Content(context, isWide: isWide)
                                  else
                                    _buildStep2Content(context, isWide: isWide),
                                  const SizedBox(height: 32),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  _editorActionBar(
                    horizontalPadding: hPad,
                    maxWidth: maxWidth,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editorActionBar({
    required double horizontalPadding,
    required double maxWidth,
  }) {
    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 12,
              ),
              child: _bottomActions(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomActions(BuildContext context) {
    if (_currentStep == 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _navigationButton(),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              key: const ValueKey('community-continue-button-0'),
              onPressed: _submitting ? null : _submit,
              style: OutlinedButton.styleFrom(
                foregroundColor: green,
                side: BorderSide(color: green.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.post == null
                        ? 'community.post_meal'.tr
                        : 'common.save_changes'.tr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.check_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return _primaryActionButton(
      buttonKey: ValueKey('community-continue-button-$_currentStep'),
      label:
          widget.post == null
              ? 'community.post_meal'.tr
              : 'common.save_changes'.tr,
      icon: Icons.chevron_right_rounded,
      onPressed: _submitting ? null : _submit,
    );
  }

  Widget _primaryActionButton({
    required Key buttonKey,
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) => SizedBox(
    width: double.infinity,
    height: 52,
    child: FilledButton(
      key: buttonKey,
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: green,
        foregroundColor: Colors.white,
        disabledBackgroundColor: context.appMutedSurface,
        disabledForegroundColor: context.appMutedText,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
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
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(icon, size: 22),
                ],
              ),
    ),
  );

  Widget _navigationButton() => SizedBox(
    width: double.infinity,
    height: 52,
    child: FilledButton(
      key: ValueKey('community-navigation-button-$_currentStep'),
      onPressed: _submitting ? null : _continueToRecipe,
      style: FilledButton.styleFrom(
        backgroundColor: green,
        foregroundColor: Colors.white,
        disabledBackgroundColor: context.appMutedSurface,
        disabledForegroundColor: context.appMutedText,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
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
                  Flexible(
                    child: Text(
                      'community.continue_to_ingredients'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded, size: 22),
                ],
              ),
    ),
  );

  Widget _editorHeader() => SizedBox(
    height: AppBackButton.layoutSize,
    child: Row(
      children: [
        IconButton(
          key: const ValueKey('community-editor-back-button'),
          icon: const Icon(Icons.arrow_back_rounded, color: green, size: 24),
          onPressed: _submitting ? null : _handleBack,
        ),
        Expanded(
          child: Center(
            child: Text(
              (widget.post == null
                      ? 'community.new_meal'
                      : 'community.edit_meal')
                  .tr,
              style: TextStyle(
                color: context.appText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 48),
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

  Widget _progressHeader() {
    final isStep1 = _currentStep == 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _progressStep(
          1,
          'community.basic_info',
          isActive: isStep1,
          isComplete: !isStep1,
          onTap: () {
            if (!isStep1 && !_submitting) {
              setState(() => _currentStep = 0);
            }
          },
        ),
        Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: context.appBorder,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 250),
                widthFactor: isStep1 ? 0.5 : 1.0,
                heightFactor: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: green,
                  ),
                ),
              ),
            ),
          ),
        ),
        _progressStep(
          2,
          'community.ingredients',
          isActive: !isStep1,
          isComplete: false,
        ),
      ],
    );
  }

  Widget _progressStep(
    int number,
    String labelKey, {
    required bool isActive,
    bool isComplete = false,
    VoidCallback? onTap,
  }) {
    final isHighlighted = isActive || isComplete;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isHighlighted ? green : context.appMutedSurface,
                border: Border.all(
                  color: isHighlighted ? green : context.appBorder,
                  width: 1.5,
                ),
              ),
              child:
                  isComplete
                      ? const Icon(
                        Icons.check_rounded,
                        size: 17,
                        color: Colors.white,
                      )
                      : Text(
                        '$number',
                        style: TextStyle(
                          color:
                              isHighlighted
                                  ? Colors.white
                                  : context.appMutedText,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
            ),
            const SizedBox(height: 5),
            Text(
              labelKey.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    isHighlighted
                        ? (context.appIsDark ? const Color(0xFF86EFAC) : green)
                        : context.appMutedText,
                fontSize: 12,
                fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1Content(BuildContext context, {required bool isWide}) {
    if (isWide) {
      return Column(
        key: const ValueKey<String>('community-post-editor-step1-wide'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _step1Header(),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _coverPhotoCard(),
                    if (_images.isNotEmpty ||
                        (widget.post?.imageUrls.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 8),
                      _selectedImageStrip(),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _descriptionField(),
                    _timeAndServingsRow(),
                    _difficultySection(),
                    const SizedBox(height: 8),
                    _mealCategoryField(),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey<String>('community-post-editor-step1-single'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _step1Header(),
        const SizedBox(height: 10),
        _coverPhotoCard(),
        if (_images.isNotEmpty ||
            (widget.post?.imageUrls.isNotEmpty ?? false)) ...[
          const SizedBox(height: 8),
          _selectedImageStrip(),
        ],
        const SizedBox(height: 14),
        _descriptionField(),
        _timeAndServingsRow(),
        _difficultySection(),
        const SizedBox(height: 12),
        _mealCategoryField(),
      ],
    );
  }

  Widget _step1Header() => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'community.share_your_meal'.tr,
              style: TextStyle(
                color: context.appText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'community.basic_info_help'.tr,
              style: TextStyle(color: context.appMutedText, fontSize: 12),
            ),
          ],
        ),
      ),
      if (widget.post == null) ...[
        const SizedBox(width: 8),
        Material(
          color: context.appSoftGreen,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: _submitting ? null : _chooseFavoriteFood,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bookmark_outline_rounded,
                    size: 16,
                    color: green,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _selectedFavoriteFood?.name ??
                        'community.prefill_from_favorites_short'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: green,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ],
  );

  Widget _coverPhotoCard() => InkWell(
    onTap: _submitting ? null : _chooseImage,
    borderRadius: BorderRadius.circular(20),
    child: CustomPaint(
      foregroundPainter: _DashedRoundedBorder(
        color:
            context.appIsDark
                ? context.appColorScheme.primary.withValues(alpha: .48)
                : const Color(0xFFB7DEC7),
        radius: 20,
      ),
      child: Container(
        height: 200,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.appSubtleSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _images.isNotEmpty
                ? Image.memory(_images.first, fit: BoxFit.cover)
                : widget.post?.imageUrl.isNotEmpty == true
                ? Image.network(widget.post!.imageUrl, fit: BoxFit.cover)
                : _emptyPhotoPrompt(),
            if (_images.isNotEmpty || widget.post?.imageUrl.isNotEmpty == true)
              Positioned(
                right: 12,
                bottom: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'community.change_photo'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
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
  );

  String _titleFromDescription(String value) {
    final firstLine = value
        .split(RegExp(r'\r?\n'))
        .firstWhere((line) => line.trim().isNotEmpty, orElse: () => '')
        .trim();
    return firstLine.length <= 150 ? firstLine : firstLine.substring(0, 150);
  }

  Widget _descriptionField() => _field(
    _description,
    'community.meal_name'.tr,
    hint: 'Ex. Salad',
    icon: Icons.restaurant_rounded,
    inputIcon: Icons.restaurant_rounded,
    lines: 1,
    maxLength: 150,
    validator:
        (v) =>
            v == null || v.trim().isEmpty
                ? 'community.meal_name_required'.tr
                : null,
  );

  Widget _timeAndServingsRow() => Row(
    children: [
      Expanded(
        child: _field(
          _time,
          'Cooking time',
          hint: 'Ex. 40',
          suffix: 'min',
          icon: Icons.schedule_rounded,
          inputIcon: Icons.schedule_rounded,
          keyboard: TextInputType.number,
          validator: (v) => _positive(v, 'Cooking time'),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _field(
          _servings,
          'Servings',
          hint: '1',
          suffix: 'servings',
          icon: Icons.group_outlined,
          inputIcon: Icons.group_outlined,
          keyboard: TextInputType.number,
          validator: (v) => _positive(v, 'Servings'),
        ),
      ),
    ],
  );

  Widget _difficultySection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.appSoftGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.tune_rounded, color: green, size: 13),
          ),
          const SizedBox(width: 7),
          Text(
            'common.difficulty'.tr,
            style: TextStyle(
              color: context.appText,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          _difficultyCard(
            'EASY',
            Icons.sentiment_satisfied_alt_rounded,
            green,
          ),
          const SizedBox(width: 8),
          _difficultyCard(
            'MEDIUM',
            Icons.sentiment_neutral_rounded,
            const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 8),
          _difficultyCard(
            'HARD',
            Icons.sentiment_dissatisfied_rounded,
            const Color(0xFFEF4444),
          ),
        ],
      ),
    ],
  );

  Widget _difficultyCard(String value, IconData icon, Color activeColor) {
    final selected = _difficulty == value;
    final isDark = context.appIsDark;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _difficulty = value),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 46,
          decoration: BoxDecoration(
            color:
                selected
                    ? (value == 'EASY'
                        ? (isDark
                            ? const Color(0xFF143020)
                            : const Color(0xFFEAF8F0))
                        : activeColor.withValues(alpha: isDark ? 0.22 : 0.12))
                    : context.appElevatedSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  selected
                      ? (value == 'EASY' ? green : activeColor)
                      : context.appBorder,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected ? null : context.appTileShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color:
                    selected
                        ? (value == 'EASY' ? green : activeColor)
                        : context.appMutedText,
              ),
              const SizedBox(width: 6),
              Text(
                value[0] + value.substring(1).toLowerCase(),
                style: TextStyle(
                  color:
                      selected
                          ? (value == 'EASY' ? green : activeColor)
                          : context.appText,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2Content(BuildContext context, {required bool isWide}) {
    if (isWide) {
      return Column(
        key: const ValueKey<String>('community-post-editor-step2-wide'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: _ingredientsSection(),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _howToCookSection(),
                    const SizedBox(height: 18),
                    _tagsSection(),
                    const SizedBox(height: 18),
                    _audienceSection(),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey<String>('community-post-editor-step2-single'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ingredientsSection(),
        const SizedBox(height: 20),
        _howToCookSection(),
        const SizedBox(height: 20),
        _tagsSection(),
        const SizedBox(height: 20),
        _audienceSection(),
      ],
    );
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    bool optional = false,
    Widget? trailing,
  }) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: context.appSoftGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 19, color: green),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (optional)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.appSoftGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'community.optional'.tr,
                        style: const TextStyle(
                          color: green,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appMutedText,
                  fontSize: 11.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing,
        ],
      ],
    ),
  );

  Widget _ingredientsSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader(
        title: 'community.ingredients'.tr,
        subtitle: 'community.ingredients_help'.tr,
        icon: Icons.shopping_basket_outlined,
        optional: true,
        trailing: InkWell(
          key: const ValueKey('community-add-custom-ingredient-button'),
          onTap: _showAddCustomIngredientSheet,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: context.appSoftGreen,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: green.withValues(alpha: .3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, size: 14, color: green),
                const SizedBox(width: 4),
                Text(
                  'community.custom_ingredient'.tr,
                  style: const TextStyle(
                    color: green,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        key: const ValueKey('community-ingredient-search-input'),
        controller: _ingredientSearchController,
        onChanged: _searchIngredients,
        onTap: () {
          if (_ingredientSearchController.text.trim().isNotEmpty) {
            setState(() => _showIngredientSuggestions = true);
          }
        },
        decoration: _decoration(
          hint: 'community.search_grocery_hint'.tr,
          prefixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.search_rounded, size: 20),
          ),
        ).copyWith(
          suffixIcon:
              _ingredientSearchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _ingredientSearchController.clear();
                      setState(() {
                        _ingredientSuggestions = const [];
                        _showIngredientSuggestions = false;
                      });
                    },
                  )
                  : null,
        ),
        textInputAction: TextInputAction.search,
      ),
      if (_showIngredientSuggestions &&
          (_ingredientSuggestions.isNotEmpty ||
              _ingredientSearchController.text.trim().isNotEmpty)) ...[
        const SizedBox(height: 8),
        _ingredientSuggestionPanel(),
      ],
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'community.amount_label'.tr,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                TextFormField(
                  key: const ValueKey('community-ingredient-amount-input'),
                  controller: _ingredientAmountController,
                  focusNode: _ingredientAmountFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _decoration(
                    hint: 'community.amount_placeholder'.tr,
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _onAddIngredientTapped(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'community.unit_label'.tr,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final chosen = await _showIngredientUnitPicker(
                        _selectedUnit,
                      );
                      if (chosen != null && mounted) {
                        setState(() {
                          _selectedUnit = chosen;
                          _newIngredient.unit = chosen;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: InputDecorator(
                      decoration: _decoration(),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedUnit,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.appText,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: context.appMutedText,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: SizedBox(
              height: 48,
              child: FilledButton(
                key: const ValueKey('community-add-ingredient'),
                onPressed: _onAddIngredientTapped,
                style: FilledButton.styleFrom(
                  backgroundColor: context.appSoftGreen,
                  foregroundColor: green,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 18, color: green),
                    const SizedBox(width: 4),
                    Text(
                      'common.add'.tr,
                      style: const TextStyle(
                        color: green,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      if (_ingredients.isNotEmpty) ...[
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${'community.added_ingredients'.tr} (${_ingredients.length})',
              style: TextStyle(
                color: context.appText,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            InkWell(
              onTap: () {
                for (final item in _ingredients) {
                  item.dispose();
                }
                setState(_ingredients.clear);
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Text(
                  'community.clear_all'.tr,
                  style: const TextStyle(
                    color: green,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._ingredients.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Container(
            key: ValueKey('ingredient-row-${item.hashCode}-$index'),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: context.appElevatedSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.appBorder),
              boxShadow: context.appTileShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.appSoftGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: green,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.name.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${item.amount.text} ${item.unit}',
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'community.edit_ingredient'.tr,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () => _editIngredient(index),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  color: context.appMutedText,
                ),
                IconButton(
                  tooltip: 'community.remove_item'.trParams({
                    'name': item.name.text,
                  }),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    item.dispose();
                    setState(() => _ingredients.removeAt(index));
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 17),
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),
          );
        }),
      ],
    ],
  );

  void _onAddIngredientTapped() {
    final searchName = _ingredientSearchController.text.trim();
    final newName = _newIngredient.name.text.trim();
    final name = searchName.isNotEmpty ? searchName : newName;
    final amountText =
        _ingredientAmountController.text.trim().isNotEmpty
            ? _ingredientAmountController.text.trim()
            : _newIngredient.amount.text.trim();
    final amount = num.tryParse(amountText);
    if (name.isEmpty || amount == null || amount <= 0) {
      Get.snackbar(
        'community.add_ingredient_details'.tr,
        'community.ingredient_details_help'.tr,
      );
      return;
    }
    setState(() {
      _ingredients.add(
        _IngredientInput(name: name, amount: amountText, unit: _selectedUnit),
      );
      _ingredientSearchController.clear();
      _ingredientAmountController.clear();
      _newIngredient.name.clear();
      _newIngredient.amount.clear();
      _ingredientSuggestions = const [];
      _showIngredientSuggestions = false;
    });
    FocusScope.of(context).unfocus();
  }

  Widget _howToCookSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader(
        title: 'community.how_to_cook'.tr,
        subtitle: 'community.cooking_steps_help'.tr,
        icon: Icons.restaurant_menu_rounded,
        optional: true,
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.appElevatedSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.appBorder),
          boxShadow: context.appTileShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step ${_steps.length + 1}',
              style: TextStyle(
                color: context.appText,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const ValueKey('community-new-cooking-step-input'),
              controller: _currentStepInputController,
              minLines: 3,
              maxLines: 5,
              decoration: _decoration(
                hint: 'community.describe_cooking_step'.tr,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 38,
                child: FilledButton(
                  key: const ValueKey('community-add-another-step'),
                  onPressed: _onAddStepToListTapped,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.appSoftGreen,
                    foregroundColor: green,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 16, color: green),
                      const SizedBox(width: 4),
                      Text(
                        'community.add_step_to_list'.tr,
                        style: const TextStyle(
                          color: green,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
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
      if (_steps.isNotEmpty) ...[
        const SizedBox(height: 10),
        ..._steps.asMap().entries.map((entry) {
          final index = entry.key;
          final stepController = entry.value;
          return Container(
            key: ValueKey('step-row-${stepController.hashCode}-$index'),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.appElevatedSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.appBorder),
              boxShadow: context.appTileShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(top: 2, right: 10),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: green,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      stepController.text,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'community.edit_step'.tr,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () => _showAddOrEditStepSheet(index: index),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  color: context.appMutedText,
                ),
                IconButton(
                  tooltip: 'community.remove_step'.trParams({
                    'number': '${index + 1}',
                  }),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    stepController.dispose();
                    setState(() => _steps.removeAt(index));
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 17),
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),
          );
        }),
      ],
    ],
  );

  void _onAddStepToListTapped() {
    final text = _currentStepInputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _steps.add(TextEditingController(text: text));
      _currentStepInputController.clear();
    });
    FocusScope.of(context).unfocus();
  }

  Widget _tagsSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader(
        title: 'community.tags_optional'.tr,
        subtitle: 'community.tags_help'.tr,
        icon: Icons.sell_outlined,
      ),
      const SizedBox(height: 8),
      if (_tagsLoading)
        const Align(
          alignment: Alignment.centerLeft,
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
      else if (_tagsError != null)
        _inlineError('community.tags_load_error'.tr, _loadTags)
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._tags.where((tag) => _selectedTags.contains(tag.id)).map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.appSoftGreen,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#${tag.name}',
                      style: const TextStyle(
                        color: green,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap:
                          _submitting
                              ? null
                              : () => setState(
                                () => _selectedTags.remove(tag.id),
                              ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: green,
                      ),
                    ),
                  ],
                ),
              );
            }),
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: const ValueKey('community-add-tag'),
                onTap: _submitting ? null : _showTagPicker,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: green, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 16, color: green),
                      const SizedBox(width: 4),
                      Text(
                        'community.add_tag'.tr,
                        style: const TextStyle(
                          color: green,
                          fontSize: 12.5,
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
    ],
  );

  Widget _audienceSection() => Column(
    key: const ValueKey<String>('community-post-audience'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader(
        title: 'community.who_can_see_it'.tr,
        subtitle: 'community.who_can_see_it_subtitle'.tr,
        icon: Icons.visibility_outlined,
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: context.appElevatedSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.appBorder),
          boxShadow: context.appTileShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _audienceTile(
              visibility: CommunityPostVisibility.public,
              title: 'Public',
              subtitle: 'community.public_audience_desc'.tr,
              icon: Icons.public_rounded,
            ),
            Divider(
              height: 1,
              indent: 58,
              endIndent: 16,
              color: context.appBorder,
            ),
            _audienceTile(
              visibility: CommunityPostVisibility.followers,
              title: 'Followers',
              subtitle: 'community.followers_audience_desc'.tr,
              icon: Icons.person_outline_rounded,
            ),
          ],
        ),
      ),
    ],
  );

  Widget _audienceTile({
    required CommunityPostVisibility visibility,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _visibility == visibility;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _visibility = visibility),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.appSoftGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 19, color: green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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

  Widget _emptyPhotoPrompt() => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 360;
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          constraints: const BoxConstraints(maxWidth: 480),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: compact ? 120 : 150,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: compact ? 58 : 68,
                      height: compact ? 58 : 68,
                      decoration: BoxDecoration(
                        color: context.appSoftGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_a_photo_outlined,
                        color: green,
                        size: compact ? 28 : 32,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'community.add_cover_photo'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'community.cover_photo_help_short'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: compact ? 10.5 : 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: compact ? 130 : 165,
                height: 175,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: 0,
                      top: 36,
                      child: Transform.rotate(
                        angle: .15,
                        child: _samplePhoto(
                          'assets/images/meals/slideshow2.png',
                          compact ? 60 : 70,
                          compact ? 95 : 108,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 24,
                      top: 0,
                      child: Transform.rotate(
                        angle: -.04,
                        child: _samplePhoto(
                          'assets/images/meals/slideshow1.png',
                          compact ? 76 : 88,
                          compact ? 76 : 88,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      bottom: 24,
                      child: Transform.rotate(
                        angle: -.06,
                        child: _samplePhoto(
                          'assets/images/meals/healthy_salad.jpg',
                          compact ? 90 : 105,
                          compact ? 105 : 122,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Transform.rotate(
                        angle: -.05,
                        child: Text(
                          'community.good_food_caption'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF247842),
                            fontSize: compact ? 11 : 12.5,
                            height: 1.05,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _samplePhoto(String asset, double width, double height) => Container(
    width: width,
    height: height,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Color(0x26000000),
          blurRadius: 7,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: Image.asset(asset, fit: BoxFit.cover),
    ),
  );

  Widget _selectedImageStrip() {
    final existing = widget.post?.imageUrls ?? const <String>[];
    final canAdd = _images.length + existing.length < _maxImages;
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: existing.length + _images.length + (canAdd ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index < existing.length) {
            return _imagePreview(
              child: Image.network(existing[index], fit: BoxFit.cover),
              label: index == 0 ? 'community.cover'.tr : null,
            );
          }
          final localIndex = index - existing.length;
          if (localIndex < _images.length) {
            return _imagePreview(
              child: Image.memory(_images[localIndex], fit: BoxFit.cover),
              label: index == 0 ? 'community.cover'.tr : null,
              onRemove: () => setState(() => _images.removeAt(localIndex)),
            );
          }
          return InkWell(
            onTap: _chooseImage,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 76,
              decoration: BoxDecoration(
                color: context.appSoftGreen,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: green.withValues(alpha: .35)),
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                color: green,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _imagePreview({
    required Widget child,
    String? label,
    VoidCallback? onRemove,
  }) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(width: 76, height: 76, child: child),
      ),
      if (label != null)
        Positioned(
          left: 5,
          bottom: 5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      if (onRemove != null)
        Positioned(
          right: 3,
          top: 3,
          child: InkWell(
            onTap: onRemove,
            child: const CircleAvatar(
              radius: 10,
              backgroundColor: Color(0xB8000000),
              child: Icon(Icons.close_rounded, color: Colors.white, size: 14),
            ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.appSoftGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.restaurant_rounded, color: green, size: 13),
              ),
              const SizedBox(width: 7),
              Text(
                'community.meal_category'.tr,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color:
                    selectedCategory == null
                        ? context.appElevatedSurface
                        : context.appSelectedSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selectedCategory == null ? context.appBorder : green,
                  width: selectedCategory == null ? 1 : 1.4,
                ),
                boxShadow: context.appTileShadow,
              ),
              child: InkWell(
                onTap: _submitting ? null : _showMealCategoryPicker,
                borderRadius: BorderRadius.circular(16),
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
                              selectedCategory == null
                                  ? context.appSoftGreen
                                  : green,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _mealCategoryIcon(selectedCategory?.name ?? ''),
                          color: selectedCategory == null ? green : Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedCategory?.name ??
                                  'community.choose_meal_category'.tr,
                              style: TextStyle(
                                color:
                                    selectedCategory == null
                                        ? context.appText
                                        : context.appColorScheme.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedCategory == null
                                  ? 'community.category_approval_help'.tr
                                  : 'common.tap_to_change'.tr,
                              style: TextStyle(
                                color: context.appMutedText,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: green,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_showValidation && _selectedCategoryId == null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text(
                'community.select_meal_category'.tr,
                style: const TextStyle(color: Color(0xFFCF3B3B), fontSize: 12),
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
                    Text(
                      'community.choose_meal_category'.tr,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'community.category_approval_help'.tr,
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

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    String? suffix,
    IconData? icon,
    IconData? inputIcon,
    int lines = 1,
    int? maxLength,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
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
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: lines,
          maxLength: maxLength,
          keyboardType: keyboard,
          validator: validator,
          decoration: _decoration(
            hint: hint,
            suffix: suffix,
            prefixIcon:
                inputIcon != null
                    ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 14),
                        Icon(inputIcon, size: 19, color: context.appMutedText),
                        const SizedBox(width: 10),
                        Container(
                          width: 1,
                          height: 20,
                          color: context.appBorder,
                        ),
                        const SizedBox(width: 12),
                      ],
                    )
                    : null,
          ),
        ),
      ],
    ),
  );

  InputDecoration _decoration({
    String? hint,
    String? suffix,
    Widget? prefixIcon,
  }) => InputDecoration(
    hintText: hint,
    suffixText: suffix,
    prefixIcon: prefixIcon,
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    filled: true,
    fillColor: context.appElevatedSurface,
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
        TextButton(onPressed: retry, child: Text('common.retry'.tr)),
      ],
    ),
  );
  Future<String?> _showIngredientUnitPicker([String? initialUnit]) async {
    FocusScope.of(context).unfocus();
    final currentUnit = (initialUnit ?? _newIngredient.unit).trim();
    final availableUnits =
        <String>{
          ..._ingredientUnits,
          if (_newIngredient.unit.trim().isNotEmpty) _newIngredient.unit.trim(),
          if (currentUnit.isNotEmpty) currentUnit,
        }.toList();
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
                    'community.choose_measurement_unit'.tr,
                    style: TextStyle(
                      color: sheetContext.appText,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'community.measurement_unit_help'.tr,
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
                    itemCount: availableUnits.length,
                    itemBuilder: (context, index) {
                      final unit = availableUnits[index];
                      final isSelected = unit == currentUnit;
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
    if (initialUnit == null && selected != null && mounted) {
      setState(() => _newIngredient.unit = selected);
    }
    return selected;
  }

  Widget _ingredientSuggestionPanel() {
    final query = _ingredientSearchController.text.trim();
    final hasExactMatch = _ingredientSuggestions.any(
      (s) => s.name.trim().toLowerCase() == query.toLowerCase(),
    );
    final showCustomOption = query.isNotEmpty && !hasExactMatch;
    final totalCount =
        _ingredientSuggestions.length + (showCustomOption ? 1 : 0);

    return Container(
      constraints: const BoxConstraints(maxHeight: 190),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appColorScheme.primary.withValues(alpha: .4),
        ),
        boxShadow: context.appTileShadow,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: totalCount,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (showCustomOption && index == 0) {
            return Material(
              color: Colors.transparent,
              child: ListTile(
                dense: true,
                leading: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.appSoftGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, color: green, size: 16),
                ),
                title: Text(
                  'community.use_custom_ingredient'.trParams({'name': query}),
                  style: const TextStyle(
                    color: green,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                trailing: Text(
                  'community.custom_ingredient'.tr,
                  style: TextStyle(color: context.appMutedText, fontSize: 11),
                ),
                onTap: () => _selectCustomIngredient(query),
              ),
            );
          }
          final ingredientIndex = showCustomOption ? index - 1 : index;
          final ingredient = _ingredientSuggestions[ingredientIndex];
          return Material(
            color: Colors.transparent,
            child: ListTile(
              dense: true,
              leading:
                  const Icon(Icons.restaurant_rounded, color: green, size: 20),
              title: Text(
                ingredient.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
              trailing:
                  ingredient.defaultUnit.isEmpty
                      ? null
                      : Text(
                        ingredient.defaultUnit,
                        style: TextStyle(color: context.appMutedText),
                      ),
              onTap: () => _selectIngredient(ingredient),
            ),
          );
        },
      ),
    );
  }
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
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: ListTile(
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
        subtitle: Text('community.create_select_tag'.tr),
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
