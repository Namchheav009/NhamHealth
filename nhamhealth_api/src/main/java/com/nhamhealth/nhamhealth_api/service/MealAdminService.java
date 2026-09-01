package com.nhamhealth.nhamhealth_api.service;

import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.cache.annotation.Cacheable;

import jakarta.persistence.EntityManager;

import com.nhamhealth.nhamhealth_api.dto.response.MealAdminRowDto;
import com.nhamhealth.nhamhealth_api.dto.response.AdminMealEditorDto;
import com.nhamhealth.nhamhealth_api.dto.response.AdminRecipeStepDto;
import com.nhamhealth.nhamhealth_api.dto.response.AdminMealIngredientDto;
import com.nhamhealth.nhamhealth_api.dto.response.AdminMealNutritionDto;
import com.nhamhealth.nhamhealth_api.dto.response.AdminMealReviewDto;
import com.nhamhealth.nhamhealth_api.dto.response.MealAdminAggregateProjection;
import com.nhamhealth.nhamhealth_api.dto.request.AdminMealRequest;
import com.nhamhealth.nhamhealth_api.entity.Ingredient;
import com.nhamhealth.nhamhealth_api.entity.MealIngredient;
import com.nhamhealth.nhamhealth_api.entity.RecipeStep;
import com.nhamhealth.nhamhealth_api.entity.Meal;
import com.nhamhealth.nhamhealth_api.entity.MealCategory;
import com.nhamhealth.nhamhealth_api.repository.MealFavoriteRepository;
import com.nhamhealth.nhamhealth_api.repository.MealRepository;
import com.nhamhealth.nhamhealth_api.repository.MealCategoryRepository;
import com.nhamhealth.nhamhealth_api.repository.MealTagRepository;
import com.nhamhealth.nhamhealth_api.repository.RecipeStepRepository;
import com.nhamhealth.nhamhealth_api.repository.IngredientRepository;
import com.nhamhealth.nhamhealth_api.repository.MealIngredientRepository;
import com.nhamhealth.nhamhealth_api.repository.MealNutritionRepository;

@Service
public class MealAdminService {

    private final MealRepository mealRepository;
    private final MealTagRepository mealTagRepository;
    private final MealFavoriteRepository mealFavoriteRepository;
    private final MealCategoryRepository mealCategoryRepository;
    private final RecipeStepRepository recipeStepRepository;
    private final IngredientRepository ingredientRepository;
    private final MealIngredientRepository mealIngredientRepository;
    private final MealNutritionRepository mealNutritionRepository;
    private final ProfileImageStorageService profileImageStorageService;
    private final EntityManager entityManager;

    public MealAdminService(
            MealRepository mealRepository,
            MealTagRepository mealTagRepository,
            MealFavoriteRepository mealFavoriteRepository,
            MealCategoryRepository mealCategoryRepository,
            RecipeStepRepository recipeStepRepository,
            IngredientRepository ingredientRepository,
            MealIngredientRepository mealIngredientRepository,
            MealNutritionRepository mealNutritionRepository,
            ProfileImageStorageService profileImageStorageService,
            EntityManager entityManager) {
        this.mealRepository = mealRepository;
        this.mealTagRepository = mealTagRepository;
        this.mealFavoriteRepository = mealFavoriteRepository;
        this.mealCategoryRepository = mealCategoryRepository;
        this.recipeStepRepository = recipeStepRepository;
        this.ingredientRepository = ingredientRepository;
        this.mealIngredientRepository = mealIngredientRepository;
        this.mealNutritionRepository = mealNutritionRepository;
        this.profileImageStorageService = profileImageStorageService;
        this.entityManager = entityManager;
    }

    public Page<MealAdminRowDto> getMealsForAdmin(
            String search, String category, String status, String tag, Pageable pageable) {
        return mealRepository.findForAdmin(
                normalizeFilter(search), normalizeFilter(category), normalizeFilter(status), normalizeFilter(tag), pageable)
            .map(this::toAdminRow);
    }

    public long getMealCount() {
        return mealRepository.count();
    }

    public double getAverageRating() {
        return 0;
    }

    public long getFavoriteCount() {
        return mealFavoriteRepository.countAllFavorites();
    }

    @org.springframework.transaction.annotation.Transactional
    public MealAdminRowDto createMeal(AdminMealRequest request) {
        Meal meal = new Meal();
        applyMealRequest(meal, request);
        java.time.LocalDateTime now = java.time.LocalDateTime.now();
        meal.setCreatedAt(now);
        meal.setUpdatedAt(now);
        Meal savedMeal = mealRepository.save(meal);
        saveMealIngredients(savedMeal, request);
        saveRecipeSteps(savedMeal, request);
        return toAdminRow(savedMeal);
    }

    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    public AdminMealEditorDto getMealForEdit(Integer mealId) {
        Meal meal = findMeal(mealId);
        List<AdminRecipeStepDto> recipeSteps = recipeStepRepository.findByMealMealIdOrderByStepNumberAsc(mealId).stream()
                .map(step -> new AdminRecipeStepDto(
                        step.getStepId(), step.getStepNumber(), step.getStepTitle(), step.getInstruction(), step.getImageUrl()))
                .toList();
        List<AdminMealIngredientDto> ingredients = mealIngredientRepository.findByMealMealIdOrderByDisplayOrderAsc(mealId).stream()
                .map(ingredient -> new AdminMealIngredientDto(
                        ingredient.getIngredient().getIngredientId(), ingredient.getIngredient().getIngredientName(),
                        ingredient.getIngredient().getDefaultUnit(), ingredient.getQuantity(), ingredient.getUnit(),
                        ingredient.getPreparationNote()))
                .toList();
            List<AdminMealNutritionDto> nutrition = mealNutritionRepository.findByMealMealIdOrderByNutrientDisplayOrderAsc(mealId).stream()
                .map(item -> new AdminMealNutritionDto(
                    item.getNutrient().getNutrientId(), item.getNutrient().getNutrientName(),
                    item.getAmountPerServing(), item.getNutrient().getUnit()))
                .toList();
            List<AdminMealReviewDto> reviews = List.of();
        return new AdminMealEditorDto(
                meal.getMealId(), meal.getMealName(), meal.getCategory().getCategoryId(), meal.getCaloriesCached(),
                meal.getServings(), meal.getDescription(), meal.getDifficulty(), meal.getCookingTimeMinutes(),
                Boolean.TRUE.equals(meal.getIsPublished()), meal.getMainImageUrl(), ingredients, nutrition, recipeSteps, reviews);
    }

    @org.springframework.transaction.annotation.Transactional
    public MealAdminRowDto updateMeal(Integer mealId, AdminMealRequest request) {
        Meal meal = findMeal(mealId);
        applyMealRequest(meal, request);
        meal.setUpdatedAt(java.time.LocalDateTime.now());
        Meal savedMeal = mealRepository.save(meal);
        mealIngredientRepository.deleteByMealMealId(mealId);
        recipeStepRepository.deleteByMealMealId(mealId);
        entityManager.flush();
        saveMealIngredients(savedMeal, request);
        saveRecipeSteps(savedMeal, request);
        return toAdminRow(savedMeal);
    }

    @org.springframework.transaction.annotation.Transactional
    public void deleteMeal(Integer mealId) {
        findMeal(mealId);
        deleteRelatedRows("ai_recommendation_items", mealId);
        deleteRelatedRows("recipe_steps", mealId);
        deleteRelatedRows("meal_tags", mealId);
        deleteRelatedRows("meal_favorites", mealId);
        deleteRelatedRows("meal_ingredients", mealId);
        deleteRelatedRows("meal_nutrition", mealId);
        mealRepository.deleteById(mealId);
    }

    private void applyMealRequest(Meal meal, AdminMealRequest request) {
        MealCategory category = mealCategoryRepository.findById(request.categoryId())
                .orElseThrow(() -> new IllegalArgumentException("Selected meal category was not found"));
        if (!profileImageStorageService.isStoredMealImageUrl(request.mainImageUrl())) {
            throw new IllegalArgumentException("Upload a meal image before saving the meal");
        }
        meal.setMealName(request.mealName().trim());
        meal.setCategory(category);
        meal.setMainImageUrl(request.mainImageUrl().trim());
        meal.setDescription(blankToNull(request.description()));
        meal.setDifficulty(blankToNull(request.difficulty()));
        meal.setCookingTimeMinutes(request.cookingTimeMinutes());
        meal.setServings(request.servings());
        meal.setCaloriesCached(request.calories());
        meal.setIsPublished(request.published());
    }

    private void saveRecipeSteps(Meal savedMeal, AdminMealRequest request) {
        List<RecipeStep> recipeSteps = new java.util.ArrayList<>();
        for (int index = 0; index < request.recipeSteps().size(); index++) {
            var requestedStep = request.recipeSteps().get(index);
            RecipeStep recipeStep = new RecipeStep();
            recipeStep.setMeal(savedMeal);
            recipeStep.setStepNumber(index + 1);
            recipeStep.setStepTitle(blankToNull(requestedStep.title()));
            recipeStep.setInstruction(requestedStep.instruction().trim());
            if (!profileImageStorageService.isStoredRecipeStepImageUrl(requestedStep.imageUrl())) {
                throw new IllegalArgumentException("Upload an image for every recipe step before saving the meal");
            }
            recipeStep.setImageUrl(requestedStep.imageUrl().trim());
            recipeSteps.add(recipeStep);
        }
        recipeStepRepository.saveAll(recipeSteps);
    }

    private void saveMealIngredients(Meal savedMeal, AdminMealRequest request) {
        java.util.Set<Integer> selectedIngredientIds = new java.util.HashSet<>();
        List<MealIngredient> mealIngredients = new java.util.ArrayList<>();
        for (int index = 0; index < request.ingredients().size(); index++) {
            var requestedIngredient = request.ingredients().get(index);
            if (!selectedIngredientIds.add(requestedIngredient.ingredientId())) {
                throw new IllegalArgumentException("Each ingredient can only be added once");
            }
            Ingredient ingredient = ingredientRepository.findById(requestedIngredient.ingredientId())
                    .orElseThrow(() -> new IllegalArgumentException("Selected ingredient was not found"));
            MealIngredient mealIngredient = new MealIngredient();
            mealIngredient.setMeal(savedMeal);
            mealIngredient.setIngredient(ingredient);
            mealIngredient.setQuantity(requestedIngredient.quantity());
            mealIngredient.setUnit(blankToNull(requestedIngredient.unit()));
            mealIngredient.setPreparationNote(blankToNull(requestedIngredient.preparationNote()));
            mealIngredient.setDisplayOrder(index + 1);
            mealIngredients.add(mealIngredient);
        }
        mealIngredientRepository.saveAll(mealIngredients);
    }

    private Meal findMeal(Integer mealId) {
        return mealRepository.findById(mealId)
                .orElseThrow(() -> new IllegalArgumentException("Meal was not found"));
    }

    private void deleteRelatedRows(String tableName, Integer mealId) {
        entityManager.createNativeQuery("DELETE FROM " + tableName + " WHERE meal_id = :mealId")
                .setParameter("mealId", mealId)
                .executeUpdate();
    }

    public List<MealCategory> getActiveCategories() {
        return mealCategoryRepository.findAllByOrderBySortOrderAsc().stream()
                .filter(category -> Boolean.TRUE.equals(category.getIsActive()))
                .toList();
    }

    @Cacheable("mealTagNames")
    public List<String> getMealTags() {
        return mealTagRepository.findDistinctTagNames();
    }

    private String normalize(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private String normalizeFilter(String value) {
        return value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private MealAdminRowDto toAdminRow(Meal meal) {
        String category = meal.getCategory() != null ? meal.getCategory().getCategoryName() : "Uncategorized";
        String status = Boolean.TRUE.equals(meal.getIsPublished()) ? "Published" : "Draft";
        String calories = meal.getCaloriesCached() == null ? "—"
                : meal.getCaloriesCached().setScale(0, java.math.RoundingMode.HALF_UP).toPlainString() + " kcal";
        String servingSize = meal.getServings() == null ? "—" : meal.getServings() + " serving";
        String updatedDate = meal.getUpdatedAt() == null ? "—"
                : meal.getUpdatedAt().format(java.time.format.DateTimeFormatter.ofPattern("MMM dd, yyyy"));

        List<String> tags = mealTagRepository.findByMealMealId(meal.getMealId()).stream()
                .map(tag -> tag.getTag() != null ? tag.getTag().getTagName() : null)
                .filter(tag -> tag != null && !tag.isBlank())
                .collect(Collectors.toList());

        List<AdminMealReviewDto> reviews = List.of();
        double averageRating = 0;
        String rating = String.format("%.1f", averageRating);

        long favorites = mealFavoriteRepository.countByMealMealId(meal.getMealId());

        return new MealAdminRowDto(
                meal.getMealId(),
                mealIconClass(category),
                meal.getMainImageUrl(),
                profileImageStorageService.mealThumbnailUrl(meal.getMainImageUrl()),
                meal.getMealName(),
                category,
                calories,
                servingSize,
                tags,
                rating,
                reviews.size(),
                Math.toIntExact(favorites),
                status,
                updatedDate);
    }

        private MealAdminRowDto toAdminRow(MealAdminAggregateProjection meal) {
        String category = meal.getCategory() == null ? "Uncategorized" : meal.getCategory();
        String status = Boolean.TRUE.equals(meal.getPublished()) ? "Published" : "Draft";
        String calories = meal.getCalories() == null ? "—"
            : meal.getCalories().setScale(0, java.math.RoundingMode.HALF_UP).toPlainString() + " kcal";
        String servingSize = meal.getServings() == null ? "—" : meal.getServings() + " serving";
        String updatedDate = meal.getUpdatedAt() == null ? "—"
            : meal.getUpdatedAt().format(java.time.format.DateTimeFormatter.ofPattern("MMM dd, yyyy"));
        List<String> tags = mealTagRepository.findByMealMealId(meal.getMealId()).stream()
            .map(tag -> tag.getTag() != null ? tag.getTag().getTagName() : null)
            .filter(tag -> tag != null && !tag.isBlank())
            .collect(Collectors.toList());
        return new MealAdminRowDto(
            meal.getMealId(), mealIconClass(category), meal.getMainImageUrl(),
            profileImageStorageService.mealThumbnailUrl(meal.getMainImageUrl()), meal.getMealName(), category,
            calories, servingSize, tags, String.format("%.1f", meal.getRating() == null ? 0 : meal.getRating()),
            Math.toIntExact(meal.getReviewCount()), Math.toIntExact(meal.getFavorites()), status, updatedDate);
        }

    private String mealIconClass(String category) {
        String normalized = category == null ? "" : category.toLowerCase();
        if (normalized.contains("soup") || normalized.contains("bowl")) {
            return "bi-egg-fried";
        }
        if (normalized.contains("salad")) {
            return "bi-leaf";
        }
        if (normalized.contains("breakfast")) {
            return "bi-egg";
        }
        if (normalized.contains("fish") || normalized.contains("salmon")) {
            return "bi-fish";
        }
        if (normalized.contains("stir") || normalized.contains("rice")) {
            return "bi-egg-fried";
        }
        return "bi-egg-fried";
    }
}
