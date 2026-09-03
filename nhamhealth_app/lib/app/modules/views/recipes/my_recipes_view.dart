import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/auth_service.dart';
import '../../../theme/app_colors.dart';
import '../../models/recipes/community_recipe.dart';
import '../../repositories/recipes/recipe_repository.dart';

class MyRecipesView extends StatefulWidget {
  const MyRecipesView({super.key});

  @override
  State<MyRecipesView> createState() => _MyRecipesViewState();
}

class _MyRecipesViewState extends State<MyRecipesView> {
  late final RecipeRepository _repository;
  List<CommunityRecipe> _recipes = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = RecipeRepository(authService: Get.find<AuthService>());
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _recipes = await _repository.mine();
    } catch (error) {
      if (mounted) {
        Get.snackbar('Recipes unavailable', '$error');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _run(
    CommunityRecipe recipe,
    Future<CommunityRecipe> Function() action,
  ) async {
    try {
      final updated = await action();
      setState(() {
        _recipes =
            _recipes
                .map((item) => item.id == recipe.id ? updated : item)
                .toList();
      });
    } catch (error) {
      Get.snackbar('Unable to continue', '$error');
    }
  }

  Future<void> _delete(CommunityRecipe recipe) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete meal post?'),
        content: Text(
          'This permanently removes "${recipe.name}" from Community and Meals.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.delete(recipe.id);
      if (mounted) {
        setState(
          () =>
              _recipes =
                  _recipes.where((item) => item.id != recipe.id).toList(),
        );
      }
    } catch (error) {
      Get.snackbar('Meal post not deleted', '$error');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My meal posts'),
      actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () async {
        final created = await Get.to<CommunityRecipe>(
          () => _RecipeEditor(repository: _repository),
        );
        if (created != null) {
          setState(() => _recipes = [created, ..._recipes]);
        }
      },
      icon: const Icon(Icons.add_rounded),
      label: const Text('Create meal post'),
    ),
    body:
        _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
              onRefresh: _load,
              child:
                  _recipes.isEmpty
                      ? ListView(
                        children: const [
                          SizedBox(height: 170),
                          Icon(
                            Icons.menu_book_outlined,
                            size: 56,
                            color: Color(0xFF789080),
                          ),
                          SizedBox(height: 14),
                          Center(
                            child: Text(
                              'Share your first meal with the Community.',
                            ),
                          ),
                        ],
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _recipes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final recipe = _recipes[index];
                          return _RecipeCard(
                            recipe: recipe,
                            repository: _repository,
                            onRun: _run,
                            onDelete: () => _delete(recipe),
                          );
                        },
                      ),
            ),
  );
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.repository,
    required this.onRun,
    required this.onDelete,
  });

  final CommunityRecipe recipe;
  final RecipeRepository repository;
  final Future<void> Function(
    CommunityRecipe,
    Future<CommunityRecipe> Function(),
  )
  onRun;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  recipe.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              _StatusChip(recipe.status),
            ],
          ),
          if (recipe.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                recipe.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (recipe.cookingTimeMinutes != null)
                _InfoChip(
                  Icons.timer_outlined,
                  '${recipe.cookingTimeMinutes} min',
                ),
              if (recipe.difficulty.isNotEmpty)
                _InfoChip(
                  Icons.signal_cellular_alt_rounded,
                  _displayValue(recipe.difficulty),
                ),
              _InfoChip(
                Icons.restaurant_outlined,
                '${recipe.ingredients.length} ingredients',
              ),
              if (recipe.mealId != null)
                const _InfoChip(Icons.verified_rounded, 'In Meals'),
            ],
          ),
          if (recipe.aiReviewReason.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    recipe.aiStatus == 'APPROVED'
                        ? const Color(0xFFE7F6EB)
                        : const Color(0xFFFFF4DF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(recipe.aiReviewReason),
            ),
          const SizedBox(height: 8),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Delete meal post',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
              TextButton.icon(
                onPressed:
                    () => onRun(recipe, () => repository.aiCheck(recipe.id)),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('AI check'),
              ),
              if (recipe.status == 'DRAFT')
                FilledButton.icon(
                  onPressed:
                      () => onRun(recipe, () => repository.publish(recipe.id)),
                  icon: const Icon(Icons.publish_outlined),
                  label: const Text('Publish'),
                ),
            ],
          ),
        ],
      ),
    ),
  );

  static String _displayValue(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return '';
    return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }
}

class _RecipeEditor extends StatefulWidget {
  const _RecipeEditor({required this.repository});

  final RecipeRepository repository;

  @override
  State<_RecipeEditor> createState() => _RecipeEditorState();
}

class _RecipeEditorState extends State<_RecipeEditor> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _time = TextEditingController();
  final _servings = TextEditingController();
  final _ingredient = TextEditingController();
  final _step = TextEditingController();

  final _ingredients = <RecipeIngredient>[];
  final _steps = <RecipeStep>[];
  Uint8List? _image;
  bool _saving = false;
  String _difficulty = 'EASY';

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _time.dispose();
    _servings.dispose();
    _ingredient.dispose();
    _step.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) {
      setState(() => _image = bytes);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_ingredients.isEmpty || _steps.isEmpty) {
      Get.snackbar(
        'Finish your recipe',
        'Add at least one ingredient and one step.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final draft = await widget.repository.create(
        name: _name.text,
        description: _description.text,
        cookingTimeMinutes: int.tryParse(_time.text),
        servings: int.tryParse(_servings.text),
        difficulty: _difficulty,
        ingredients: _ingredients,
        steps: _steps,
        imageBytes: _image,
      );
      final recipe = await widget.repository.publish(draft.id);
      if (mounted) Get.back(result: recipe);
    } catch (error) {
      Get.snackbar('Recipe not saved', '$error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Meal Post')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Meal name'),
            validator:
                (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Enter a name'
                        : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Description'),
            minLines: 3,
            maxLines: 5,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _time,
                  decoration: const InputDecoration(labelText: 'Minutes'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _servings,
                  decoration: const InputDecoration(labelText: 'Servings'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _difficulty,
            decoration: const InputDecoration(labelText: 'Difficulty'),
            items: const [
              DropdownMenuItem(value: 'EASY', child: Text('Easy')),
              DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
              DropdownMenuItem(value: 'HARD', child: Text('Hard')),
            ],
            onChanged: (value) => setState(() => _difficulty = value ?? 'EASY'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _chooseImage,
            icon: const Icon(Icons.photo_outlined),
            label: Text(
              _image == null
                  ? 'Add cover photo (required to publish)'
                  : 'Cover photo selected',
            ),
          ),
          const SizedBox(height: 22),
          _EditableList(
            title: 'Ingredients',
            controller: _ingredient,
            hint: 'e.g. 2 tomatoes',
            values: _ingredients.map((item) => item.name).toList(),
            onAdd: () {
              if (_ingredient.text.trim().isNotEmpty) {
                setState(() {
                  _ingredients.add(RecipeIngredient(_ingredient.text.trim()));
                  _ingredient.clear();
                });
              }
            },
            onRemove: (index) => setState(() => _ingredients.removeAt(index)),
          ),
          const SizedBox(height: 20),
          _EditableList(
            title: 'Cooking steps',
            controller: _step,
            hint: 'Describe this step',
            values: _steps.map((item) => item.instruction).toList(),
            onAdd: () {
              if (_step.text.trim().isNotEmpty) {
                setState(() {
                  _steps.add(RecipeStep(_step.text.trim()));
                  _step.clear();
                });
              }
            },
            onRemove: (index) => setState(() => _steps.removeAt(index)),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Publishing…' : 'Publish Meal'),
          ),
        ],
      ),
    ),
  );
}

class _EditableList extends StatelessWidget {
  const _EditableList({
    required this.title,
    required this.controller,
    required this.hint,
    required this.values,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final String hint;
  final TextEditingController controller;
  final List<String> values;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      ...values.asMap().entries.map(
        (entry) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(radius: 14, child: Text('${entry.key + 1}')),
          title: Text(entry.value),
          trailing: IconButton(
            onPressed: () => onRemove(entry.key),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      ),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: hint),
            ),
          ),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_rounded),
          ),
        ],
      ),
    ],
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);

  final String status;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(status == 'PUBLISHED' ? 'Published' : 'Draft'),
    backgroundColor:
        status == 'PUBLISHED'
            ? context.appSoftGreen
            : context.appMutedSurface,
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) =>
      Chip(avatar: Icon(icon, size: 17), label: Text(text));
}
