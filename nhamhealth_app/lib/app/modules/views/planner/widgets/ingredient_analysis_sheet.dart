import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../models/planner/meal_plan.dart';
import '../../../providers/planner/meal_planner_provider.dart';
import '../../wellness/widgets/ingredient_avatar.dart';
import '../planner_shared.dart';

class IngredientAnalysisSheet extends StatefulWidget {
  const IngredientAnalysisSheet({super.key, required this.item});

  final GroceryItem item;

  static Future<void> showForGroceryItem(
    BuildContext context, {
    required GroceryItem item,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IngredientAnalysisSheet(item: item),
    );
  }

  @override
  State<IngredientAnalysisSheet> createState() =>
      _IngredientAnalysisSheetState();
}

class _IngredientAnalysisSheetState extends State<IngredientAnalysisSheet> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _data;

  bool get _isKhmer => (Get.locale?.languageCode ?? 'en') == 'km';

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = Get.find<MealPlannerProvider>();
      final item = widget.item;
      final ingredients = [
        '${item.quantity > 0 ? '${item.quantity} ' : ''}${item.unit} ${item.name}'
            .trim(),
      ];

      final result = await provider.analyzeIngredients(
        mealName: item.name,
        ingredients: ingredients,
        servings: 1,
        lang: _isKhmer ? 'km' : 'en',
      );

      if (mounted) {
        setState(() {
          _data = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder:
          (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // Sheet Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isKhmer
                                  ? 'ការវិភាគគ្រឿងផ្សំ AI & Database'
                                  : 'AI & Database Ingredient Analysis',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color:
                                    isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.item.name.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Body
                Expanded(
                  child:
                      _isLoading
                          ? _buildLoadingState(isDark)
                          : _errorMessage != null
                          ? _buildErrorState(isDark)
                          : _buildContent(scrollController, isDark),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryGreen),
          const SizedBox(height: 18),
          Text(
            _isKhmer
                ? 'កំពុងវិភាគគ្រឿងផ្សំជាមួយ AI និង Database...'
                : 'Analyzing ingredients with AI and Nutrition Database...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              _errorMessage ?? 'Error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAnalysis,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_isKhmer ? 'ព្យាយាមម្តងទៀត' : 'Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ScrollController controller, bool isDark) {
    final ai = _data?['aiAnalysis'] as Map<String, dynamic>? ?? {};
    final matchedCount = _data?['databaseMatchedCount'] as int? ?? 0;
    final totalCount = _data?['totalIngredients'] as int? ?? 0;
    final ingredients =
        (_data?['ingredients'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

    final rating = ai['healthRating'] as String? ?? 'B';
    final score = ai['healthScore'] as int? ?? 80;
    final headline = ai['headline'] as String? ?? '';
    final summary = ai['summary'] as String? ?? '';
    final benefits =
        (ai['healthBenefits'] as List<dynamic>? ?? []).cast<String>();
    final warnings =
        (ai['warningsAndAllergens'] as List<dynamic>? ?? []).cast<String>();
    final tips = (ai['smartTips'] as List<dynamic>? ?? []).cast<String>();

    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(20),
      children: [
        // AI Health Rating Card
        _buildRatingCard(rating, score, headline, summary, isDark),
        const SizedBox(height: 16),

        // Database matching stats and partial nutrition estimates
        _buildDatabaseVerifiedCard(matchedCount, totalCount, isDark),
        const SizedBox(height: 16),

        // Database Ingredients Details
        if (ingredients.isNotEmpty) ...[
          _buildSectionTitle(
            _isKhmer ? 'ការផ្គូផ្គងគ្រឿងផ្សំ' : 'Ingredient Database Matches',
            isDark,
          ),
          const SizedBox(height: 8),
          ...ingredients.map((item) => _buildIngredientRow(item, isDark)),
          const SizedBox(height: 18),
        ],

        // Health Benefits
        if (benefits.isNotEmpty) ...[
          _buildSectionTitle(
            _isKhmer ? 'អត្ថប្រយោជន៍សុខភាព' : 'Health Benefits',
            isDark,
          ),
          const SizedBox(height: 8),
          ...benefits.map(
            (b) => _buildBulletItem(
              b,
              Icons.check_circle_rounded,
              const Color(0xFF059669),
              isDark,
            ),
          ),
          const SizedBox(height: 18),
        ],

        // Warnings & Allergens
        if (warnings.isNotEmpty) ...[
          _buildSectionTitle(
            _isKhmer ? 'ការប្រុងប្រយ័ត្ន & អាលែកហ្ស៊ី' : 'Warnings & Allergens',
            isDark,
          ),
          const SizedBox(height: 8),
          ...warnings.map(
            (w) => _buildBulletItem(
              w,
              Icons.warning_amber_rounded,
              const Color(0xFFD97706),
              isDark,
            ),
          ),
          const SizedBox(height: 18),
        ],

        // Smart Tips
        if (tips.isNotEmpty) ...[
          _buildSectionTitle(
            _isKhmer ? 'គន្លឹះចម្អិន & ជីវជាតិ' : 'Smart Culinary Tips',
            isDark,
          ),
          const SizedBox(height: 8),
          ...tips.map(
            (t) => _buildBulletItem(
              t,
              Icons.lightbulb_outline_rounded,
              const Color(0xFF3B82F6),
              isDark,
            ),
          ),
          const SizedBox(height: 18),
        ],

        // Disclaimer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _isKhmer
                ? 'ព័ត៌មាននេះផ្តល់ជូនសម្រាប់គោលបំណងអប់រំសុខភាពទូទៅតែប៉ុណ្ណោះ មិនមែនជាការណែនាំវេជ្ជសាស្ត្រផ្លូវការឡើយ។'
                : 'This information is generated for general wellness educational purposes, not formal medical advice.',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRatingCard(
    String rating,
    int score,
    String headline,
    String summary,
    bool isDark,
  ) {
    Color gradeColor;
    switch (rating.toUpperCase()) {
      case 'A':
        gradeColor = const Color(0xFF059669);
        break;
      case 'B':
        gradeColor = const Color(0xFF0D9488);
        break;
      case 'C':
        gradeColor = const Color(0xFFD97706);
        break;
      case 'UNRATED':
        gradeColor = const Color(0xFF64748B);
        break;
      default:
        gradeColor = const Color(0xFFE11D48);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gradeColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gradeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: gradeColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradeColor.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  rating,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                Text(
                  '$score/100',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (headline.isNotEmpty)
                  Text(
                    headline,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    summary,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseVerifiedCard(int matched, int total, bool isDark) {
    final pct = total > 0 ? (matched / total) : 0.0;
    final cal = (_data?['totalCalories'] as num?)?.toDouble() ?? 0;
    final pro = (_data?['totalProtein'] as num?)?.toDouble() ?? 0;
    final carb = (_data?['totalCarbs'] as num?)?.toDouble() ?? 0;
    final fat = (_data?['totalFat'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                color: AppColors.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isKhmer
                      ? 'ផ្គូផ្គងក្នុង Database: $matched/$total មុខ'
                      : 'Matched in Database: $matched/$total ingredients',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              Text(
                '${(pct * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor:
                  isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              color: AppColors.primaryGreen,
              minHeight: 6,
            ),
          ),
          if (matched > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildMacroChip('🔥 ${cal.toInt()} kcal', isDark),
                _buildMacroChip('🥩 ${pro.toStringAsFixed(1)}g Pro', isDark),
                _buildMacroChip('🍚 ${carb.toStringAsFixed(1)}g Carb', isDark),
                _buildMacroChip('🥑 ${fat.toStringAsFixed(1)}g Fat', isDark),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white70 : const Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildIngredientRow(Map<String, dynamic> item, bool isDark) {
    final original = item['originalText'] as String? ?? '';
    final matched = item['matched'] as bool? ?? false;
    final matchedFoodName = item['matchedFoodName'] as String? ?? '';
    final rawImageUrl = item['imageUrl'] as String? ?? '';
    final cal = (item['calories'] as num?)?.toDouble() ?? 0;
    final pro = (item['protein'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          IngredientAvatar(
            name: matchedFoodName.isEmpty ? original : matchedFoodName,
            imageUrl:
                rawImageUrl.trim().isEmpty
                    ? null
                    : plannerImageUrl(rawImageUrl),
            size: 42,
            borderRadius: 11,
          ),
          const SizedBox(width: 10),
          Icon(
            matched
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: matched ? AppColors.primaryGreen : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  original,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                if (matched &&
                    matchedFoodName.isNotEmpty &&
                    matchedFoodName.toLowerCase() != original.toLowerCase())
                  Text(
                    _isKhmer
                        ? 'ផ្គូផ្គង: $matchedFoodName'
                        : 'Matched: $matchedFoodName',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
          if (matched && cal > 0)
            Text(
              '${cal.toInt()} kcal · ${pro.toStringAsFixed(1)}g',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(
    String text,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
    );
  }
}
