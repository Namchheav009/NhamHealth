package com.nhamhealth.nhamhealth_api.service;

import static org.springframework.http.HttpStatus.FORBIDDEN;
import static org.springframework.http.HttpStatus.NOT_FOUND;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

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

    public RecipeFlowService(RecipeRepository recipes, RecipeIngredientRepository ingredients,
            RecipeStepRepository steps, RecipeTagRepository recipeTags, TagTypeRepository tags,
            AiRecipeReviewRepository reviews, UserRecipeAiCheckRepository checks,
            SavedRecipeRepository savedRecipes, PostRepository posts,
            MealRepository meals, MealCategoryRepository categories, UserRepository users,
            ProfileImageStorageService images) {
        this.recipes = recipes; this.ingredients = ingredients; this.steps = steps; this.recipeTags = recipeTags;
        this.tags = tags; this.reviews = reviews; this.checks = checks; this.savedRecipes = savedRecipes;
        this.posts = posts; this.meals = meals; this.categories = categories;
        this.users = users; this.images = images;
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
        meals.findBySourceRecipeRecipeId(recipeId).ifPresent(meals::delete);
        recipes.delete(recipe);
    }

    private void promoteApproved(Recipe recipe) {
        Meal meal = meals.findBySourceRecipeRecipeId(recipe.getRecipeId()).orElse(null);
        if (meal == null) {
            MealCategory category = categories.findAllByOrderBySortOrderAsc().stream().findFirst()
                    .orElseThrow(() -> new IllegalStateException("Create a meal category before approving Community meals."));
            meal = new Meal(); meal.setSourceRecipe(recipe); meal.setSourceType("COMMUNITY"); meal.setApprovalSource("AI");
            meal.setCategory(category); meal.setCreatedByUser(recipe.getAuthor()); meal.setMealName(recipe.getRecipeName());
            meal.setDescription(recipe.getDescription()); meal.setMainImageUrl(recipe.getMainImageUrl());
            meal.setCookingTimeMinutes(recipe.getCookingTimeMinutes()); meal.setServings(recipe.getServings()); meal.setDifficulty(recipe.getDifficulty());
            meal.setIsPublished(true); meal.setCreatedAt(LocalDateTime.now()); meal.setUpdatedAt(meal.getCreatedAt()); meal = meals.save(meal);
        }
        recipe.setMeal(meal);
        recipes.save(recipe);
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
        if (image != null && !image.isEmpty()) recipe.setMainImageUrl(images.storePostImage(image));
        if (update) { ingredients.deleteByRecipeRecipeId(recipe.getRecipeId()); steps.deleteByRecipeRecipeId(recipe.getRecipeId()); recipeTags.deleteByRecipeRecipeId(recipe.getRecipeId()); }
        List<RecipeIngredient> ingredientRows = new ArrayList<>();
        for (int i = 0; i < list(request.ingredients()).size(); i++) { RecipeIngredientRequest item = list(request.ingredients()).get(i); RecipeIngredient row = new RecipeIngredient(); row.setRecipe(recipe); row.setIngredientName(item.name().trim()); row.setAmount(item.amount()); row.setUnit(clean(item.unit())); row.setPreparationNote(clean(item.preparationNote())); row.setDisplayOrder(i); ingredientRows.add(row); }
        List<RecipeStep> stepRows = new ArrayList<>();
        for (int i = 0; i < list(request.steps()).size(); i++) { RecipeStepRequest item = list(request.steps()).get(i); RecipeStep row = new RecipeStep(); row.setRecipe(recipe); row.setStepNumber(i + 1); row.setStepTitle(clean(item.title())); row.setInstruction(item.instruction().trim()); stepRows.add(row); }
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
        if (recipe.getDescription() == null || recipe.getDescription().isBlank()) gaps.add("a description");
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
