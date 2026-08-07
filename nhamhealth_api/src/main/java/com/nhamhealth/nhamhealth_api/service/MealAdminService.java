package com.nhamhealth.nhamhealth_api.service;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import jakarta.persistence.EntityManager;

import com.nhamhealth.nhamhealth_api.dto.response.MealAdminRowDto;
import com.nhamhealth.nhamhealth_api.dto.response.AdminMealEditorDto;
import com.nhamhealth.nhamhealth_api.dto.response.AdminRecipeStepDto;
import com.nhamhealth.nhamhealth_api.dto.request.AdminMealRequest;
import com.nhamhealth.nhamhealth_api.entity.RecipeStep;
import com.nhamhealth.nhamhealth_api.entity.Meal;
import com.nhamhealth.nhamhealth_api.entity.MealCategory;
import com.nhamhealth.nhamhealth_api.entity.Review;
import com.nhamhealth.nhamhealth_api.repository.MealFavoriteRepository;
import com.nhamhealth.nhamhealth_api.repository.MealRepository;
import com.nhamhealth.nhamhealth_api.repository.MealCategoryRepository;
import com.nhamhealth.nhamhealth_api.repository.MealTagRepository;
import com.nhamhealth.nhamhealth_api.repository.ReviewRepository;
import com.nhamhealth.nhamhealth_api.repository.RecipeStepRepository;

@Service
public class MealAdminService {

    private final MealRepository mealRepository;
    private final MealTagRepository mealTagRepository;
    private final MealFavoriteRepository mealFavoriteRepository;
    private final ReviewRepository reviewRepository;
    private final MealCategoryRepository mealCategoryRepository;
    private final RecipeStepRepository recipeStepRepository;
    private final EntityManager entityManager;

    public MealAdminService(
            MealRepository mealRepository,
            MealTagRepository mealTagRepository,
            MealFavoriteRepository mealFavoriteRepository,
            ReviewRepository reviewRepository,
            MealCategoryRepository mealCategoryRepository,
            RecipeStepRepository recipeStepRepository,
            EntityManager entityManager) {
        this.mealRepository = mealRepository;
        this.mealTagRepository = mealTagRepository;
        this.mealFavoriteRepository = mealFavoriteRepository;
        this.reviewRepository = reviewRepository;
        this.mealCategoryRepository = mealCategoryRepository;
        this.recipeStepRepository = recipeStepRepository;
        this.entityManager = entityManager;
    }

    public List<MealAdminRowDto> getMealsForAdmin() {
        return mealRepository.findAllByOrderByUpdatedAtDesc().stream()
                .map(this::toAdminRow)
                .collect(Collectors.toList());
    }

    @org.springframework.transaction.annotation.Transactional
    public MealAdminRowDto createMeal(AdminMealRequest request) {
        Meal meal = new Meal();
        applyMealRequest(meal, request);
        java.time.LocalDateTime now = java.time.LocalDateTime.now();
        meal.setCreatedAt(now);
        meal.setUpdatedAt(now);
        Meal savedMeal = mealRepository.save(meal);
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
        return new AdminMealEditorDto(
                meal.getMealId(), meal.getMealName(), meal.getCategory().getCategoryId(), meal.getCaloriesCached(),
                meal.getServings(), meal.getDescription(), meal.getDifficulty(), meal.getCookingTimeMinutes(),
                Boolean.TRUE.equals(meal.getIsPublished()), meal.getMainImageUrl(), recipeSteps);
    }

    @org.springframework.transaction.annotation.Transactional
    public MealAdminRowDto updateMeal(Integer mealId, AdminMealRequest request) {
        Meal meal = findMeal(mealId);
        applyMealRequest(meal, request);
        meal.setUpdatedAt(java.time.LocalDateTime.now());
        Meal savedMeal = mealRepository.save(meal);
        recipeStepRepository.deleteByMealMealId(mealId);
        entityManager.flush();
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
        deleteRelatedRows("reviews", mealId);
        deleteRelatedRows("meal_ingredients", mealId);
        deleteRelatedRows("meal_nutrition", mealId);
        entityManager.createNativeQuery("UPDATE meal_logs SET meal_id = NULL WHERE meal_id = :mealId")
                .setParameter("mealId", mealId)
                .executeUpdate();
        entityManager.createNativeQuery("UPDATE posts SET tagged_meal_id = NULL WHERE tagged_meal_id = :mealId")
                .setParameter("mealId", mealId)
                .executeUpdate();
        mealRepository.deleteById(mealId);
    }

    private void applyMealRequest(Meal meal, AdminMealRequest request) {
        MealCategory category = mealCategoryRepository.findById(request.categoryId())
                .orElseThrow(() -> new IllegalArgumentException("Selected meal category was not found"));
        if (!request.mainImageUrl().startsWith("/uploads/meal-images/")) {
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
            if (!requestedStep.imageUrl().startsWith("/uploads/recipe-step-images/")) {
                throw new IllegalArgumentException("Upload an image for every recipe step before saving the meal");
            }
            recipeStep.setImageUrl(requestedStep.imageUrl().trim());
            recipeSteps.add(recipeStep);
        }
        recipeStepRepository.saveAll(recipeSteps);
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

        List<Review> reviews = reviewRepository.findByMealMealId(meal.getMealId());
        double averageRating = reviews.stream()
                .filter(review -> review.getRating() != null)
                .mapToDouble(Review::getRating)
                .average()
                .orElse(0.0);
        String reviewsText = reviews.isEmpty() ? "0 (0)" : String.format("%.1f (%d)", averageRating, reviews.size());

        long favorites = mealFavoriteRepository.countByMealMealId(meal.getMealId());

        return new MealAdminRowDto(
                meal.getMealId(),
                mealIconClass(category),
                meal.getMainImageUrl(),
                meal.getMealName(),
                category,
                calories,
                servingSize,
                tags,
                reviewsText,
                Math.toIntExact(favorites),
                status,
                updatedDate);
    }

    private String mealIconClass(String category) {
        String normalized = category == null ? "" : category.toLowerCase();
        if (normalized.contains("soup") || normalized.contains("bowl")) {
            return "fa-bowl-food";
        }
        if (normalized.contains("salad")) {
            return "fa-leaf";
        }
        if (normalized.contains("breakfast")) {
            return "fa-egg";
        }
        if (normalized.contains("fish") || normalized.contains("salmon")) {
            return "fa-fish";
        }
        if (normalized.contains("stir") || normalized.contains("rice")) {
            return "fa-bowl-rice";
        }
        return "fa-utensils";
    }
}
