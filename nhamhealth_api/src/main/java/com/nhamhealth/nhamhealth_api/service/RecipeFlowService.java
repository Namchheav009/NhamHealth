package com.nhamhealth.nhamhealth_api.service;

import static org.springframework.http.HttpStatus.FORBIDDEN;
import static org.springframework.http.HttpStatus.NOT_FOUND;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.Objects;
import java.util.Set;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import jakarta.persistence.EntityManager;

import com.nhamhealth.nhamhealth_api.dto.request.RecipeIngredientRequest;
import com.nhamhealth.nhamhealth_api.dto.request.RecipeRequest;
import com.nhamhealth.nhamhealth_api.dto.request.RecipeStepRequest;
import com.nhamhealth.nhamhealth_api.dto.response.RecipeResponse;
import com.nhamhealth.nhamhealth_api.entity.AiRecipeReview;
import com.nhamhealth.nhamhealth_api.entity.Meal;
import com.nhamhealth.nhamhealth_api.entity.MealCategory;
import com.nhamhealth.nhamhealth_api.entity.Recipe;
import com.nhamhealth.nhamhealth_api.entity.RecipeIngredient;
import com.nhamhealth.nhamhealth_api.entity.RecipeStep;
import com.nhamhealth.nhamhealth_api.entity.RecipeTag;
import com.nhamhealth.nhamhealth_api.entity.SavedRecipe;
import com.nhamhealth.nhamhealth_api.entity.TagType;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserRecipeAiCheck;
import com.nhamhealth.nhamhealth_api.repository.AiRecipeReviewRepository;
import com.nhamhealth.nhamhealth_api.repository.MealCategoryRepository;
import com.nhamhealth.nhamhealth_api.repository.MealRepository;
import com.nhamhealth.nhamhealth_api.repository.PostRepository;
import com.nhamhealth.nhamhealth_api.repository.RecipeIngredientRepository;
import com.nhamhealth.nhamhealth_api.repository.RecipeRepository;
import com.nhamhealth.nhamhealth_api.repository.RecipeStepRepository;
import com.nhamhealth.nhamhealth_api.repository.RecipeTagRepository;
import com.nhamhealth.nhamhealth_api.repository.SavedRecipeRepository;
import com.nhamhealth.nhamhealth_api.repository.TagTypeRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRecipeAiCheckRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

/** The author-owned Community recipe lifecycle and its auditable AI gate. */
@Service
public class RecipeFlowService {
    private static final String REVIEW_MODEL = "NhamHealth recipe-readiness v1";
    private final RecipeRepository recipes;
    private final RecipeIngredientRepository ingredients;
    private final RecipeStepRepository steps;
    private final RecipeTagRepository recipeTags;
    private final TagTypeRepository tags;
    private final AiRecipeReviewRepository reviews;
    private final UserRecipeAiCheckRepository checks;
    private final SavedRecipeRepository savedRecipes;
    private final PostRepository posts;
    private final MealRepository meals;
    private final MealCategoryRepository categories;
    private final UserRepository users;
    private final ProfileImageStorageService images;
    private final EntityManager entityManager;

    public RecipeFlowService(RecipeRepository recipes, RecipeIngredientRepository ingredients,
            RecipeStepRepository steps, RecipeTagRepository recipeTags, TagTypeRepository tags,
            AiRecipeReviewRepository reviews, UserRecipeAiCheckRepository checks,
            SavedRecipeRepository savedRecipes, PostRepository posts,
            MealRepository meals, MealCategoryRepository categories, UserRepository users,
            ProfileImageStorageService images, EntityManager entityManager) {
        this.recipes = recipes; this.ingredients = ingredients; this.steps = steps; this.recipeTags = recipeTags;
        this.tags = tags; this.reviews = reviews; this.checks = checks; this.savedRecipes = savedRecipes;
        this.posts = posts; this.meals = meals; this.categories = categories;
        this.users = users; this.images = images;
        this.entityManager = entityManager;
    }

    @Transactional(readOnly = true)
    public List<RecipeResponse> mine(Integer userId) {
        return recipes.findByAuthorUserIdOrderByUpdatedAtDesc(userId).stream().map(recipe -> response(recipe, userId)).toList();
    }

    @Transactional(readOnly = true)
    public List<RecipeResponse> feed(Integer viewerId) {
        return recipes.findByStatusOrderByPublishedAtDesc("PUBLISHED").stream()
                .map(recipe -> response(recipe, viewerId)).toList();
    }

    @Transactional(readOnly = true)
    public RecipeResponse detail(Integer viewerId, Integer recipeId) {
        Recipe recipe = recipe(recipeId);
        if (!recipe.getAuthor().getUserId().equals(viewerId) && !"PUBLISHED".equals(recipe.getStatus())) {
            throw new ResponseStatusException(NOT_FOUND, "Recipe not found");
        }
        return response(recipe, viewerId);
    }

    @Transactional(readOnly = true)
    public List<RecipeResponse> saved(Integer userId) {
        return savedRecipes.findByUserUserIdOrderBySavedAtDesc(userId).stream()
                .map(SavedRecipe::getRecipe).filter(recipe -> "PUBLISHED".equals(recipe.getStatus()))
                .map(recipe -> response(recipe, userId)).toList();
    }

    @Transactional
    public RecipeResponse create(Integer userId, RecipeRequest request, MultipartFile image) {
        Recipe recipe = new Recipe();
        recipe.setAuthor(user(userId));
        recipe.setStatus("DRAFT");
        LocalDateTime now = LocalDateTime.now();
        recipe.setCreatedAt(now); recipe.setUpdatedAt(now);
        apply(recipe, request, image, false);
        return response(recipes.save(recipe), userId);
    }

    @Transactional
    public RecipeResponse update(Integer userId, Integer recipeId, RecipeRequest request, MultipartFile image) {
        Recipe recipe = owned(userId, recipeId);
        apply(recipe, request, image, true);
        recipe.setAiStatus("PENDING");
        recipe.setAiReviewReason(null);
        recipe.setUpdatedAt(LocalDateTime.now());
        return response(recipes.save(recipe), userId);
    }

    @Transactional
    public RecipeResponse publish(Integer userId, Integer recipeId) {
        Recipe recipe = owned(userId, recipeId);
        if (!"PUBLISHED".equals(recipe.getStatus())) {
            LocalDateTime now = LocalDateTime.now();
            recipe.setStatus("PUBLISHED"); recipe.setPublishedAt(now); recipe.setUpdatedAt(now);
            recipes.save(recipe);
        }
        return runAiCheck(userId, recipeId);
    }

    @Transactional
    public RecipeResponse runAiCheck(Integer userId, Integer recipeId) {
        Recipe recipe = owned(userId, recipeId);
        List<String> gaps = readinessGaps(recipe);
        String status = gaps.isEmpty() ? "APPROVED" : "INCOMPLETE";
        String feedback = gaps.isEmpty()
                ? "Recipe is complete and has been added to Meals."
                : "Add or improve: " + String.join(", ", gaps) + ".";
        recipe.setAiStatus(status);
        recipe.setAiReviewReason(feedback);
        recipes.save(recipe);
        AiRecipeReview review = new AiRecipeReview(); review.setRecipe(recipe); review.setStatus(status);
        review.setSummary(gaps.isEmpty() ? "Ready for catalog promotion" : "More recipe details are needed");
        review.setFeedback(feedback); review.setModelName(REVIEW_MODEL); review.setModelResponse("{\"missing\":" + gaps.size() + "}");
        review.setCreatedAt(LocalDateTime.now()); review = reviews.save(review);
        UserRecipeAiCheck check = new UserRecipeAiCheck(); check.setUser(user(userId)); check.setRecipe(recipe);
        check.setAiRecipeReview(review); check.setStatus(status); check.setCreatedAt(review.getCreatedAt()); checks.save(check);
        if ("APPROVED".equals(status)) promoteApproved(recipe);
        return response(recipe, userId);
    }

    @Transactional
    public void delete(Integer userId, Integer recipeId) {
        Recipe recipe = owned(userId, recipeId);

        // A promoted catalog meal and the meal post reference each other. Clear
        // the post -> meal reference before deleting the derived catalog meal.
        // This also lets the same delete path work for both author and admin
        // actions.
        Optional<Meal> promotedMeal = meals.findBySourceRecipeRecipeId(recipeId);
        if (recipe.getMeal() != null) {
            recipe.setMeal(null);
            recipes.saveAndFlush(recipe);
        }

        // The Community view uses the meal-post id as its post id. These rows
        // do not have database foreign keys because the parent is a view, but
        // they must not be left orphaned when an admin permanently removes a
        // meal post. Reports must precede comments and comment likes.
        deleteByMealPostId("post_reports", recipeId);
        entityManager.createNativeQuery("DELETE FROM comment_likes WHERE comment_id IN "
                        + "(SELECT comment_id FROM post_comments WHERE user_meal_post_id = :postId)")
                .setParameter("postId", recipeId)
                .executeUpdate();
        deleteByMealPostId("post_comments", recipeId);
        deleteByMealPostId("post_favorites", recipeId);
        deleteByMealPostId("post_likes", recipeId);
        deleteByMealPostId("post_media", recipeId);
        deleteByMealPostId("post_tags", recipeId);

        // Delete dependent rows in foreign-key order. In particular, AI check
        // records reference both the meal post and its AI review, so removing
        // only the parent post caused the FK violation shown to administrators.
        checks.deleteByRecipeRecipeId(recipeId);
        checks.flush();
        reviews.deleteByRecipeRecipeId(recipeId);
        savedRecipes.deleteByRecipeRecipeId(recipeId);
        ingredients.deleteByRecipeRecipeId(recipeId);
        steps.deleteByRecipeRecipeId(recipeId);
        recipeTags.deleteByRecipeRecipeId(recipeId);
        entityManager.flush();

        promotedMeal.ifPresent(this::deletePromotedMeal);
        recipes.delete(recipe);
        recipes.flush();
    }

    private void deletePromotedMeal(Meal meal) {
        Integer mealId = meal.getMealId();
        deleteByMealId("ai_recommendation_items", mealId);
        deleteByMealId("recipe_steps", mealId);
        deleteByMealId("meal_tags", mealId);
        deleteByMealId("meal_favorites", mealId);
        deleteByMealId("meal_ingredients", mealId);
        deleteByMealId("meal_nutrition", mealId);
        entityManager.createNativeQuery("UPDATE meal_logs SET meal_id = NULL WHERE meal_id = :mealId")
                .setParameter("mealId", mealId)
                .executeUpdate();
        meals.delete(meal);
        meals.flush();
    }

    private void deleteByMealPostId(String tableName, Integer mealPostId) {
        entityManager.createNativeQuery("DELETE FROM " + tableName + " WHERE user_meal_post_id = :postId")
                .setParameter("postId", mealPostId)
                .executeUpdate();
    }

    private void deleteByMealId(String tableName, Integer mealId) {
        entityManager.createNativeQuery("DELETE FROM " + tableName + " WHERE meal_id = :mealId")
                .setParameter("mealId", mealId)
                .executeUpdate();
    }

    private void promoteApproved(Recipe recipe) {
        Meal meal = meals.findBySourceRecipeRecipeId(recipe.getRecipeId()).orElse(null);
        if (meal == null) {
            MealCategory category = recipe.getCategory() == null ? communityMealCategory() : recipe.getCategory();
            meal = new Meal(); meal.setSourceRecipe(recipe); meal.setSourceType("COMMUNITY"); meal.setApprovalSource("AI");
            meal.setCategory(category); meal.setCreatedByUser(recipe.getAuthor()); meal.setMealName(recipe.getRecipeName());
            meal.setDescription(recipe.getDescription()); meal.setMainImageUrl(recipe.getMainImageUrl());
            meal.setCookingTimeMinutes(recipe.getCookingTimeMinutes()); meal.setServings(recipe.getServings()); meal.setDifficulty(recipe.getDifficulty());
            meal.setIsPublished(true); meal.setCreatedAt(LocalDateTime.now()); meal.setUpdatedAt(meal.getCreatedAt()); meal = meals.save(meal);
        }
        recipe.setMeal(meal);
        recipes.save(recipe);
    }

    /**
     * Community publishing must not fail just because a fresh installation has
     * not configured its meal catalogue yet. Prefer an active category and
     * create a stable fallback only when the catalogue is empty.
     */
    private MealCategory communityMealCategory() {
        List<MealCategory> existing = categories.findAllByOrderBySortOrderAsc();
        Optional<MealCategory> active = existing.stream()
                .filter(category -> Boolean.TRUE.equals(category.getIsActive()))
                .findFirst();
        if (active.isPresent()) return active.get();

        Optional<MealCategory> fallback = categories.findByCategoryNameIgnoreCase("Community Meals");
        if (fallback.isPresent()) {
            MealCategory category = fallback.get();
            category.setIsActive(true);
            return categories.save(category);
        }

        MealCategory category = new MealCategory();
        category.setCategoryName("Community Meals");
        category.setDescription("Meals approved from Community meal posts.");
        category.setSortOrder(existing.stream().map(MealCategory::getSortOrder)
                .filter(Objects::nonNull).max(Integer::compareTo).orElse(0) + 1);
        category.setIsActive(true);
        return categories.save(category);
    }

    @Transactional
    public RecipeResponse toggleSaved(Integer userId, Integer recipeId) {
        Recipe recipe = recipe(recipeId);
        if (!"PUBLISHED".equals(recipe.getStatus())) throw new ResponseStatusException(NOT_FOUND, "Recipe not found");
        Optional<SavedRecipe> existing = savedRecipes.findByUserUserIdAndRecipeRecipeId(userId, recipeId);
        if (existing.isPresent()) savedRecipes.delete(existing.get());
        else { SavedRecipe saved = new SavedRecipe(); saved.setUser(user(userId)); saved.setRecipe(recipe); saved.setSavedAt(LocalDateTime.now()); savedRecipes.save(saved); }
        return response(recipe, userId);
    }

    @Transactional(readOnly = true)
    public List<RecipeResponse> adminRecipes() {
        return recipes.findAll().stream().sorted(Comparator.comparing(Recipe::getUpdatedAt).reversed())
                .map(recipe -> response(recipe, null)).toList();
    }

    @Transactional
    public RecipeResponse adminCreate(Integer authorId, String name, String description,
            Integer cookingTimeMinutes, Integer servings, String difficulty, String status) {
        RecipeRequest request = new RecipeRequest(name, description, cookingTimeMinutes, servings,
                difficulty, List.of(), List.of(), List.of(), communityMealCategory().getCategoryId());
        RecipeResponse created = create(authorId, request, null);
        return adminUpdate(created.id(), name, description, cookingTimeMinutes, servings, difficulty, status);
    }

    @Transactional
    public RecipeResponse adminUpdate(Integer recipeId, String name, String description,
            Integer cookingTimeMinutes, Integer servings, String difficulty, String status) {
        Recipe recipe = recipe(recipeId);
        recipe.setRecipeName(name.trim());
        recipe.setDescription(clean(description));
        recipe.setCookingTimeMinutes(cookingTimeMinutes);
        recipe.setServings(servings);
        recipe.setDifficulty(clean(difficulty) == null ? null : difficulty.trim().toUpperCase(Locale.ROOT));
        String normalizedStatus = status == null ? "DRAFT" : status.trim().toUpperCase(Locale.ROOT);
        if (!Set.of("DRAFT", "PUBLISHED", "ARCHIVED").contains(normalizedStatus)) {
            throw new IllegalArgumentException("Select a valid post status.");
        }
        recipe.setStatus(normalizedStatus);
        if ("PUBLISHED".equals(normalizedStatus) && recipe.getPublishedAt() == null) {
            recipe.setPublishedAt(LocalDateTime.now());
        } else if (!"PUBLISHED".equals(normalizedStatus)) {
            recipe.setPublishedAt(null);
        }
        recipe.setAiStatus("PENDING");
        recipe.setAiReviewReason(null);
        recipe.setUpdatedAt(LocalDateTime.now());
        return response(recipes.save(recipe), null);
    }

    @Transactional
    public void adminDelete(Integer recipeId) {
        Recipe recipe = recipe(recipeId);
        delete(recipe.getAuthor().getUserId(), recipeId);
    }

    @Transactional
    public RecipeResponse promote(Integer recipeId, Integer categoryId, Integer adminUserId) {
        Recipe recipe = recipe(recipeId);
        AiRecipeReview latest = latestReview(recipeId);
        if (latest == null || !"APPROVED".equals(latest.getStatus())) {
            throw new IllegalArgumentException("Run an approved AI readiness check before promoting this recipe.");
        }
        if (meals.findBySourceRecipeRecipeId(recipeId).isEmpty()) {
            MealCategory category = categories.findById(categoryId)
                    .orElseThrow(() -> new IllegalArgumentException("Select a valid meal category."));
            Meal meal = new Meal(); meal.setSourceRecipe(recipe); meal.setSourceType("COMMUNITY"); meal.setApprovalSource("AI");
            meal.setCategory(category); meal.setCreatedByUser(user(adminUserId)); meal.setMealName(recipe.getRecipeName());
            meal.setDescription(recipe.getDescription()); meal.setMainImageUrl(recipe.getMainImageUrl());
            meal.setCookingTimeMinutes(recipe.getCookingTimeMinutes()); meal.setServings(recipe.getServings());
            meal.setIsPublished(true); meal.setCreatedAt(LocalDateTime.now()); meal.setUpdatedAt(meal.getCreatedAt()); meals.save(meal);
        }
        return response(recipe, null);
    }

    private void apply(Recipe recipe, RecipeRequest request, MultipartFile image, boolean update) {
        recipe.setRecipeName(request.recipeName().trim()); recipe.setDescription(clean(request.description()));
        recipe.setCookingTimeMinutes(request.cookingTimeMinutes()); recipe.setServings(request.servings());
        recipe.setDifficulty(clean(request.difficulty()) == null ? null : request.difficulty().trim().toUpperCase(Locale.ROOT));
        if (request.categoryId() != null) {
            MealCategory category = categories.findById(request.categoryId())
                    .orElseThrow(() -> new IllegalArgumentException("Select a valid meal category."));
            if (!Boolean.TRUE.equals(category.getIsActive())) {
                throw new IllegalArgumentException("Select an active meal category.");
            }
            recipe.setCategory(category);
        }
        if (image != null && !image.isEmpty()) recipe.setMainImageUrl(images.storePostImage(image));
        if (update) {
            // An edit replaces the child collections. Flush the deletes before
            // inserting replacement tags: otherwise Hibernate may insert a
            // tag with the same (meal post, tag) pair before its old row is
            // removed, violating uk_recipe_tags_recipe_tag and returning 500.
            ingredients.deleteByRecipeRecipeId(recipe.getRecipeId());
            steps.deleteByRecipeRecipeId(recipe.getRecipeId());
            recipeTags.deleteByRecipeRecipeId(recipe.getRecipeId());
            ingredients.flush();
            steps.flush();
            recipeTags.flush();
        }
        List<RecipeIngredient> ingredientRows = new ArrayList<>();
        for (int i = 0; i < list(request.ingredients()).size(); i++) { RecipeIngredientRequest item = list(request.ingredients()).get(i); RecipeIngredient row = new RecipeIngredient(); row.setRecipe(recipe); row.setIngredientName(item.name().trim()); row.setAmount(item.amount()); row.setUnit(clean(item.unit())); row.setPreparationNote(clean(item.preparationNote())); row.setDisplayOrder(i); ingredientRows.add(row); }
        List<RecipeStep> stepRows = new ArrayList<>();
        for (int i = 0; i < list(request.steps()).size(); i++) { RecipeStepRequest item = list(request.steps()).get(i); RecipeStep row = new RecipeStep(); row.setRecipe(recipe); row.setStepNumber(i + 1); row.setStepTitle(clean(item.title())); row.setInstruction(item.instruction().trim()); String stepImage = clean(item.imageUrl()); if (stepImage != null && !images.isStoredRecipeStepImageUrl(stepImage)) throw new IllegalArgumentException("Choose a valid cooking step image"); row.setImageUrl(stepImage); stepRows.add(row); }
        // Save the parent first for create; for updates the managed parent already has an id.
        if (recipe.getRecipeId() == null) recipes.save(recipe);
        ingredients.saveAll(ingredientRows); steps.saveAll(stepRows);
        for (Integer tagId : Set.copyOf(list(request.tagIds()))) { TagType tag = tags.findById(tagId).orElseThrow(() -> new IllegalArgumentException("One selected tag no longer exists.")); if (!Boolean.TRUE.equals(tag.getIsActive())) throw new IllegalArgumentException("Select active tags only."); RecipeTag row = new RecipeTag(); row.setRecipe(recipe); row.setTag(tag); recipeTags.save(row); }
    }

    private RecipeResponse response(Recipe recipe, Integer viewerId) {
        List<AiRecipeReview> allReviews = reviews.findByRecipeRecipeIdOrderByCreatedAtDesc(recipe.getRecipeId());
        AiRecipeReview latest = allReviews.isEmpty() ? null : allReviews.getFirst();
        Integer postId = "PUBLISHED".equals(recipe.getStatus()) ? recipe.getRecipeId() : null;
        Integer mealId = meals.findBySourceRecipeRecipeId(recipe.getRecipeId()).map(Meal::getMealId).orElse(null);
        boolean saved = viewerId != null && savedRecipes.findByUserUserIdAndRecipeRecipeId(viewerId, recipe.getRecipeId()).isPresent();
        return new RecipeResponse(recipe.getRecipeId(), value(recipe.getAuthor().getName()), recipe.getRecipeName(), value(recipe.getDescription()), value(recipe.getMainImageUrl()), recipe.getCookingTimeMinutes(), recipe.getServings(), value(recipe.getDifficulty()), recipe.getStatus(), recipe.getAiStatus(), value(recipe.getAiReviewReason()), recipe.getPublishedAt(), recipe.getCreatedAt(), recipe.getUpdatedAt(),
                recipeTags.findByRecipeRecipeId(recipe.getRecipeId()).stream().map(item -> item.getTag().getTagName()).toList(),
                ingredients.findByRecipeRecipeIdOrderByDisplayOrderAsc(recipe.getRecipeId()).stream().map(item -> new RecipeResponse.RecipeIngredient(item.getIngredientName(), item.getAmount(), value(item.getUnit()), value(item.getPreparationNote()))).toList(),
                steps.findByRecipeRecipeIdOrderByStepNumberAsc(recipe.getRecipeId()).stream().map(item -> new RecipeResponse.RecipeStep(item.getStepNumber(), value(item.getStepTitle()), item.getInstruction(), value(item.getImageUrl()))).toList(),
                latest == null ? null : new RecipeResponse.RecipeReview(latest.getStatus(), value(latest.getSummary()), value(latest.getFeedback()), value(latest.getModelName()), latest.getCreatedAt()), postId, mealId, saved);
    }

    private List<String> readinessGaps(Recipe recipe) {
        List<String> gaps = new ArrayList<>();
        if (recipe.getMainImageUrl() == null || recipe.getMainImageUrl().isBlank()) gaps.add("a cover image");
        if (recipe.getCookingTimeMinutes() == null) gaps.add("cooking time");
        if (recipe.getServings() == null) gaps.add("servings");
        if (ingredients.findByRecipeRecipeIdOrderByDisplayOrderAsc(recipe.getRecipeId()).isEmpty()) gaps.add("at least one ingredient");
        if (steps.findByRecipeRecipeIdOrderByStepNumberAsc(recipe.getRecipeId()).isEmpty()) gaps.add("at least one cooking step");
        return gaps;
    }
    private AiRecipeReview latestReview(Integer recipeId) { List<AiRecipeReview> list = reviews.findByRecipeRecipeIdOrderByCreatedAtDesc(recipeId); return list.isEmpty() ? null : list.getFirst(); }
    private Recipe recipe(Integer id) { return recipes.findById(id).orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Recipe not found")); }
    private Recipe owned(Integer userId, Integer recipeId) { Recipe recipe = recipe(recipeId); if (!recipe.getAuthor().getUserId().equals(userId)) throw new ResponseStatusException(FORBIDDEN, "You can only manage your own recipes."); return recipe; }
    private User user(Integer id) { return users.findById(id).orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "User not found")); }
    private static String clean(String value) { return value == null || value.isBlank() ? null : value.trim(); }
    private static String value(String value) { return value == null ? "" : value; }
    private static <T> List<T> list(List<T> value) { return value == null ? List.of() : value; }
}
